#!/bin/bash
# ============================================================
# 金庸群侠聊天室 - 一键部署脚本
# 适用于 Linux 服务器 (Ubuntu/CentOS/Debian)
# ============================================================
# 使用方法：
#   chmod +x deploy.sh
#   sudo ./deploy.sh
# ============================================================

set -e

echo "============================================"
echo "  🏯 金庸群侠聊天室 - 一键部署"
echo "============================================"

# ---- 配置区（按需修改）----
TARGET_DIR="/var/www/html/jin-yong-chat"
PORT=8079
NGINX_SITE_NAME="jin-yong-chat"
DOMAIN=""  # 如果有域名，填在这里，如 "chat.example.com"

# ---- 颜色输出 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# ---- 检查 root 权限 ----
if [ "$EUID" -ne 0 ]; then
    error "请使用 sudo 运行此脚本"
    exit 1
fi

# ---- 1. 安装 Node.js（如果没有）----
echo ""
echo "📦 检查 Node.js..."
if command -v node &> /dev/null; then
    info "Node.js 已安装: $(node -v)"
else
    warn "Node.js 未安装，正在安装..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    info "Node.js 已安装: $(node -v)"
fi

# ---- 2. 创建目标目录并复制文件 ----
echo ""
echo "📁 部署文件..."
mkdir -p "$TARGET_DIR"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 复制所有文件（排除 deploy.sh 自身）
rsync -av --exclude='deploy.sh' "$SCRIPT_DIR/" "$TARGET_DIR/"
info "文件已复制到 $TARGET_DIR"

# ---- 3. 安装 npm 依赖 ----
echo ""
echo "📦 安装 npm 依赖..."
cd "$TARGET_DIR"
npm init -y 2>/dev/null || true
npm install express cors dotenv
info "npm 依赖安装完成"

# ---- 4. 配置 .env（如果不存在）----
echo ""
if [ ! -f "$TARGET_DIR/.env" ]; then
    warn ".env 文件不存在，正在创建..."
    cat > "$TARGET_DIR/.env" << 'ENVEOF'
# ============================================================
# 金庸群侠聊天室 - 环境配置
# ============================================================

# 你的 API Key（必填，才能使用在线模式）
API_KEY=你的DeepSeek_API_Key

# API 地址（可选，默认 DeepSeek）
# API_URL=https://api.deepseek.com/v1/chat/completions

# 模型名称（可选，默认 deepseek-chat）
# MODEL_NAME=deepseek-chat

# 服务器端口（可选，默认 8079）
PORT=8079
ENVEOF
    info ".env 文件已创建，请编辑填入 API Key："
    echo "   nano $TARGET_DIR/.env"
else
    info ".env 文件已存在，跳过"
fi

# ---- 5. 设置文件权限 ----
echo ""
echo "🔒 设置文件权限..."
chown -R www-data:www-data "$TARGET_DIR" 2>/dev/null || true
chmod 600 "$TARGET_DIR/.env" 2>/dev/null || true
chmod 755 "$TARGET_DIR"
info "文件权限已设置"

# ---- 6. 配置 Nginx 反向代理 ----
echo ""
echo "🌐 配置 Nginx..."

# 检查 Nginx 是否安装
if command -v nginx &> /dev/null; then
    # 创建 Nginx 配置
    if [ -n "$DOMAIN" ]; then
        # 有域名 - 配置为独立站点
        cat > "/etc/nginx/sites-available/$NGINX_SITE_NAME" << NGINXEOF
server {
    listen 80;
    server_name $DOMAIN;

    # 可选：HTTPS 配置（需要先配置 SSL 证书）
    # listen 443 ssl;
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF
        info "Nginx 配置已创建（独立站点）"
    else
        # 无域名 - 配置为子路径（和 games 同级）
        cat > "/etc/nginx/sites-available/$NGINX_SITE_NAME" << NGINXEOF
server {
    listen 80;
    server_name _;

    # ===== 已有站点（如 games）的配置保持不变 =====
    # location /games/ { ... }

    # ===== 金庸群侠聊天室 =====
    location /jin-yong-chat/ {
        proxy_pass http://127.0.0.1:$PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # 静态资源缓存
        location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg)$ {
            expires 7d;
            add_header Cache-Control "public, immutable";
        }
    }
}
NGINXEOF
        info "Nginx 配置已创建（子路径模式）"
    fi

    # 启用站点
    ln -sf "/etc/nginx/sites-available/$NGINX_SITE_NAME" "/etc/nginx/sites-enabled/" 2>/dev/null || true

    # 测试 Nginx 配置
    if nginx -t 2>&1; then
        systemctl reload nginx || systemctl restart nginx
        info "Nginx 配置已生效"
    else
        error "Nginx 配置测试失败，请检查 /etc/nginx/sites-available/$NGINX_SITE_NAME"
    fi
else
    warn "Nginx 未安装，跳过 Nginx 配置"
    warn "可通过 8079 端口直接访问: http://服务器IP:$PORT"
fi

# ---- 7. 使用 PM2 设置开机自启 ----
echo ""
echo "🚀 设置开机自启..."

if command -v pm2 &> /dev/null; then
    pm2 delete jin-yong-chat 2>/dev/null || true
    cd "$TARGET_DIR"
    pm2 start server.js --name jin-yong-chat
    pm2 save
    pm2 startup 2>/dev/null || true
    info "PM2 已配置，服务将在系统重启后自动启动"
else
    warn "PM2 未安装，正在安装..."
    npm install -g pm2
    cd "$TARGET_DIR"
    pm2 start server.js --name jin-yong-chat
    pm2 save
    pm2 startup
    info "PM2 已安装并配置"
fi

# ---- 8. 完成 ----
echo ""
echo "============================================"
echo "  ✅ 部署完成！"
echo "============================================"
echo ""

# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

if [ -n "$DOMAIN" ]; then
    echo "  访问地址: http://$DOMAIN"
    echo "  (配置 HTTPS 后: https://$DOMAIN)"
elif command -v nginx &> /dev/null; then
    echo "  访问地址: http://$SERVER_IP/jin-yong-chat"
else
    echo "  访问地址: http://$SERVER_IP:$PORT"
fi

echo ""
echo "  管理命令:"
echo "    pm2 status              # 查看运行状态"
echo "    pm2 logs jin-yong-chat  # 查看日志"
echo "    pm2 restart jin-yong-chat # 重启服务"
echo ""
echo "  编辑 API Key:"
echo "    nano $TARGET_DIR/.env"
echo "    然后: pm2 restart jin-yong-chat"
echo ""
echo "============================================"
