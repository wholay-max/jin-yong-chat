// ============================================================
// 金庸群侠聊天室 - 后端代理服务器
// API Key 放在服务器端，前端通过此代理调用AI接口
// 保护 API Key 不被前端窃取
// ============================================================
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

// 加载环境变量（从 .env 文件）
try {
    require('dotenv').config({ path: path.join(__dirname, '.env') });
} catch (e) {
    // dotenv 不是必须的，没有 .env 文件也能运行
}


const app = express();
const PORT = process.env.PORT || 8079;

// ============================================================
// 日志系统
// ============================================================
const LOG_DIR = path.join(__dirname, 'logs');
const LOG_FILE = path.join(LOG_DIR, `server_${new Date().toISOString().slice(0,10)}.log`);

// 确保日志目录存在
if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
}

function getTimestamp() {
    return new Date().toLocaleString('zh-CN', { 
        hour12: false,
        timeZone: 'Asia/Shanghai'
    });
}

function writeLog(level, message, data = null) {
    const timestamp = getTimestamp();
    let logLine = `[${timestamp}] [${level}] ${message}`;
    if (data) {
        logLine += ` | ${JSON.stringify(data)}`;
    }
    // 控制台输出
    console.log(logLine);
    // 写入日志文件
    fs.appendFileSync(LOG_FILE, logLine + '\n', 'utf8');
}

// 获取真实客户端 IP（支持 Nginx 反代）
function getClientIP(req) {
    // 优先取 Nginx 传递的真实 IP
    const realIP = req.headers['x-real-ip'];
    if (realIP) return realIP;
    // 其次取 X-Forwarded-For（逗号分隔，第一个是真实 IP）
    const forwarded = req.headers['x-forwarded-for'];
    if (forwarded) return forwarded.split(',')[0].trim();
    // 最后取直连 IP
    return req.ip || req.connection.remoteAddress || 'unknown';
}

// 请求日志中间件
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        writeLog('REQ', `${req.method} ${req.path}`, {
            status: res.statusCode,
            duration: `${duration}ms`,
            ip: getClientIP(req)
        });
    });
    next();
});


// 清理旧日志（保留最近7天）
function cleanOldLogs() {
    try {
        const files = fs.readdirSync(LOG_DIR);
        const now = Date.now();
        const sevenDays = 7 * 24 * 60 * 60 * 1000;
        files.forEach(file => {
            const filePath = path.join(LOG_DIR, file);
            const stats = fs.statSync(filePath);
            if (now - stats.mtimeMs > sevenDays) {
                fs.unlinkSync(filePath);
                writeLog('INFO', `清理旧日志: ${file}`);
            }
        });
    } catch (e) {
        // 清理失败不影响主程序
    }
}
cleanOldLogs();

// 中间件
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// 静态文件服务 - 提供前端页面
app.use(express.static(path.join(__dirname)));


// ============================================================
// API 配置（从环境变量读取）
// ============================================================
const API_KEY = process.env.API_KEY || '';
const API_URL = process.env.API_URL || 'https://api.deepseek.com/v1/chat/completions';
const MODEL_NAME = process.env.MODEL_NAME || 'deepseek-chat';

// ============================================================
// 代理接口 - 前端调用此接口来让AI生成对话
// ============================================================
app.post('/api/chat', async (req, res) => {
    try {
        const { systemPrompt, messages } = req.body;

        if (!API_KEY) {
            return res.status(400).json({
                error: '服务器未配置 API Key。请在 .env 文件中设置 API_KEY，或使用离线模式。'
            });
        }

        writeLog('API', `调用模型: ${MODEL_NAME}`, {
            messagesCount: messages.length,
            systemPromptLength: systemPrompt?.length || 0
        });

        const response = await fetch(API_URL, {

            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${API_KEY}`
            },
            body: JSON.stringify({
                model: MODEL_NAME,
                messages: [
                    { role: 'system', content: systemPrompt },
                    ...messages
                ],
                temperature: 0.85,
                max_tokens: 200,
                top_p: 0.9
            })
        });

        if (!response.ok) {
            const errorText = await response.text();
            writeLog('ERR', `AI 接口错误 ${response.status}: ${errorText.substring(0, 200)}`);
            return res.status(response.status).json({
                error: `AI 接口返回错误 (${response.status})`,
                detail: errorText.substring(0, 500)
            });
        }

        const data = await response.json();
        writeLog('API', `AI 调用成功`, {
            tokens: data.usage,
            contentLength: data.choices?.[0]?.message?.content?.length || 0
        });
        res.json(data);

    } catch (error) {
        writeLog('ERR', `AI 请求失败: ${error.message}`);
        res.status(500).json({
            error: `AI 请求失败: ${error.message}`
        });
    }

});

// ============================================================
// 获取当前配置信息（不暴露 API Key）
// ============================================================
app.get('/api/config', (req, res) => {
    res.json({
        hasApiKey: !!API_KEY,
        apiUrl: API_URL,
        modelName: MODEL_NAME,
        mode: API_KEY ? 'online' : 'offline'
    });
});

// ============================================================
// 启动服务器
// ============================================================
app.listen(PORT, () => {
    writeLog('INFO', '服务器启动', {
        port: PORT,
        mode: API_KEY ? 'online' : 'offline',
        apiUrl: API_URL,
        model: MODEL_NAME,
        logFile: LOG_FILE
    });
    console.log('============================================');
    console.log('  🏯 金庸群侠聊天室 已启动！');
    console.log('============================================');
    console.log(`  地址: http://localhost:${PORT}`);
    console.log(`  模式: ${API_KEY ? '🌐 在线模式（已配置API Key）' : '📜 离线模式（未配置API Key）'}`);
    console.log(`  API: ${API_URL}`);
    console.log(`  模型: ${MODEL_NAME}`);
    console.log(`  日志: ${LOG_FILE}`);
    console.log('============================================');
    console.log('  提示: 在 .env 文件中配置 API_KEY 即可启用在线模式');
    console.log('============================================');
});


