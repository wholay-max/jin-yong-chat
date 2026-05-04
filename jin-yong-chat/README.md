# 🏯 金庸群侠聊天室

## 🚀 一键部署到服务器

### 方式一：使用部署脚本（推荐）

```bash
# 1. 将 jin-yong-chat 目录上传到服务器
# 2. SSH 登录服务器，进入目录
cd /var/www/html/jin-yong-chat

# 3. 给脚本执行权限并运行
chmod +x deploy.sh
sudo ./deploy.sh
```

脚本会自动完成：
- ✅ 安装 Node.js（如未安装）
- ✅ 复制文件到 `/var/www/html/jin-yong-chat`
- ✅ 安装 npm 依赖
- ✅ 创建 `.env` 配置文件
- ✅ 配置 Nginx 反向代理（子路径 `/jin-yong-chat`）
- ✅ 使用 PM2 设置开机自启

### 方式二：手动部署

```bash
# 1. 上传文件到服务器
# 2. 安装依赖
cd /var/www/html/jin-yong-chat
npm install express cors dotenv

# 3. 编辑 API Key
nano .env

# 4. 启动服务
node server.js
```

### 访问地址

| 方式 | 地址 |
|------|------|
| 直接访问 | `http://服务器IP:8079` |
| 通过 Nginx | `http://服务器IP/jin-yong-chat` |
| 有域名 | `http://你的域名` |

### 管理命令

```bash
pm2 status              # 查看状态
pm2 logs jin-yong-chat  # 查看日志
pm2 restart jin-yong-chat # 重启
pm2 stop jin-yong-chat   # 停止
```

---

## 快速开始（本地开发）


### 方式一：离线模式（无需配置）
直接双击打开 `index.html` 即可使用！

### 方式二：在线模式（需要 API Key）

#### 1. 配置 API Key

**方法 A：使用 .env 文件（推荐本地开发）**
1. 编辑 `.env` 文件，填入你的 API Key：
   ```
   API_KEY=你的DeepSeek_API_Key
   ```
2. 启动服务器：`node server.js`
3. 访问：`http://localhost:8079`


**方法 B：使用系统环境变量（推荐生产部署）**
```bash
# Windows (CMD)
set API_KEY=你的DeepSeek_API_Key
node server.js

# Windows (PowerShell)
$env:API_KEY="你的DeepSeek_API_Key"
node server.js

# Linux/Mac
export API_KEY=你的DeepSeek_API_Key
node server.js
```

#### 2. 启动服务器
```bash
cd jin-yong-chat
node server.js
```

#### 3. 打开浏览器
访问 `http://localhost:8079`


---

## 🔒 安全说明

### API Key 安全吗？

| 使用方式 | API Key 是否安全 | 说明 |
|---------|-----------------|------|
| 直接打开 index.html | ❌ 不安全 | API Key 在前端代码中，任何人都能看到 |
| 通过服务器访问 | ✅ 安全 | API Key 在服务器端，浏览器拿不到 |

### 部署到服务器的安全建议

1. **不要将 `.env` 提交到 Git**
   - ✅ 已配置 `.gitignore`，自动忽略 `.env`
   - 如果误提交，立即更换 API Key！

2. **生产环境推荐使用系统环境变量**
   ```bash
   # 在服务器上设置环境变量（比 .env 文件更安全）
   export API_KEY=你的Key
   node server.js
   ```

3. **使用 HTTPS**
   - 部署时务必配置 HTTPS，防止中间人攻击
   - 可以使用 Nginx 反向代理 + Let's Encrypt 免费证书

4. **限制服务器访问权限**
   - 确保 `.env` 文件权限为 600（仅所有者可读写）
   - 不要在服务器上安装不必要的软件

### 如果 API Key 泄露了怎么办？
1. 立即登录 API 平台（如 DeepSeek 控制台）
2. 删除泄露的 API Key
3. 生成新的 API Key
4. 更新服务器配置

---

## 技术架构

```
浏览器 → http://localhost:8079 → 后端代理服务器 → DeepSeek API

              ↑                        ↑
        静态文件服务              API Key 在这里
        (index.html)              (.env 或环境变量)
```

## 自定义配置

编辑 `.env` 文件或设置环境变量：

```env
# 你的 API Key（必填）
API_KEY=你的Key

# API 地址（可选，默认 DeepSeek）
API_URL=https://api.deepseek.com/v1/chat/completions

# 模型名称（可选）
MODEL_NAME=deepseek-chat

# 服务器端口（可选，默认 8079）
PORT=8079

```
