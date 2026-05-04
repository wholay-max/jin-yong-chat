🏯 金庸群侠聊天室 - 项目总结

一个可以让金庸武侠角色互相聊天的 AI 聊天室，支持用户参与对话。

---

📂 项目文件结构

jin-yong-chat/
├── index.html       ← 前端页面（古风武侠 UI）
├── server.js        ← 后端代理服务器（保护 API Key）
├── .env             ← API Key 配置（不要提交到 Git）
├── .gitignore       ← 忽略 .env 和 node_modules
├── README.md        ← 使用说明
├── SUMMARY.md       ← 本文件（项目总结）
├── deploy.sh        ← 服务器一键部署脚本
├── upload.bat       ← Windows 一键上传脚本
├── ssh.bat          ← Windows 一键 SSH 登录
└── ssh.ps1          ← PowerShell SSH 登录脚本

---

🎭 23 位金庸角色

角色
出自
说话风格
令狐冲
笑傲江湖
洒脱不羁，爱开玩笑
杨过
神雕侠侣
深情狂放，亦正亦邪
小龙女
神雕侠侣
清冷寡言，直来直去
韦小宝
鹿鼎记
油嘴滑舌，市井无赖
乔峰
天龙八部
豪气干云，重情重义
段誉
天龙八部
温文尔雅，书生气质
虚竹
天龙八部
老实憨厚，运气极好
张无忌
倚天屠龙记
优柔寡断，宅心仁厚
黄药师
射雕英雄传
孤傲清高，博学多才
洪七公
射雕英雄传
豪爽贪吃，游戏人间
郭靖
射雕英雄传
忠厚老实，大智若愚
黄蓉
射雕英雄传
冰雪聪明，古灵精怪
周伯通
射雕英雄传
天真烂漫，疯疯癫癫
欧阳锋
射雕英雄传
阴狠毒辣，武功盖世
一灯大师
射雕英雄传
慈悲为怀，佛法高深
灭绝师太
倚天屠龙记
刚烈偏激，嫉恶如仇
周芷若
倚天屠龙记
外表柔弱，内心坚韧
赵敏
倚天屠龙记
机智聪慧，敢爱敢恨
无崖子
天龙八部
飘逸出尘，武学宗师
扫地僧
天龙八部
深藏不露，佛法无边
岳不群
笑傲江湖
道貌岸然，君子剑
任盈盈
笑傲江湖
聪慧大气，圣姑风范
东方不败
笑傲江湖
雌雄莫辨，天下无敌

---

✨ 功能特性

核心功能
- ✅ 多角色聊天室：同时邀请多位金庸大侠进入聊天室
- ✅ AI 自动对话：角色之间自动聊天，最多 2 个回合
- ✅ 用户参与：用户可以发言，发言后随机角色响应
- ✅ 角色个性化：每位角色说话风格符合原著人设
- ✅ 回合制控制：可设置 1-5 个自动对话回合

技术特性
- ✅ 在线/离线双模式：有 API Key 用 AI 生成，没有则用预设台词
- ✅ API Key 安全保护：通过后端代理服务器调用 AI，前端拿不到 Key
- ✅ 多平台支持：支持 DeepSeek / SiliconFlow / OpenAI / 自定义 API
- ✅ 古风 UI：暗金武侠主题，打字机动画效果
- ✅ 导出聊天记录：一键导出为 txt 文件
- ✅ 响应式设计：手机和电脑都能用

---

🚀 部署信息

服务器配置
项目
值
服务器 IP
111.229.187.119
SSH 用户
ubuntu
SSH 端口
22
部署路径
/var/www/html/jin-yong-chat
服务端口
8079
访问地址
http://111.229.187.119:8079
Nginx 反代
http://111.229.187.119/jin-yong-chat

Nginx 配置
配置文件：/etc/nginx/sites-enabled/ap-automation.conf

location /jin-yong-chat/ {
    proxy_pass http://127.0.0.1:8079/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

常用管理命令
# SSH 登录
ssh ubuntu@111.229.187.119

# 查看服务状态
pm2 status

# 查看日志
pm2 logs jin-yong-chat

# 重启服务
pm2 restart jin-yong-chat

# 编辑 API Key
sudo nano /var/www/html/jin-yong-chat/.env
pm2 restart jin-yong-chat

# Nginx 重载
sudo nginx -t
sudo systemctl reload nginx

---

📜 部署脚本说明

upload.bat（Windows 一键上传）
双击运行，自动完成：
1. SSH 连接服务器
2. sudo mkdir 创建目录 + chmod 777 开放权限
3. 上传 6 个文件（index.html, server.js, .env, .gitignore, README.md, deploy.sh）
4. chmod 755 恢复安全权限
5. npm install 安装依赖
6. pm2 start 启动服务
deploy.sh（服务器部署脚本）
上传到服务器后执行，自动完成：
1. 安装 Node.js
2. 安装 npm 依赖
3. 配置 Nginx 反向代理
4. 使用 PM2 设置开机自启
---

🔒 安全要点

1. **API Key 存在 `.env` 中**，不要提交到 Git（已配置 `.gitignore`）
2. 通过后端代理调用 AI，前端拿不到 API Key
3. **`.env` 文件权限设为 600**（仅所有者可读写）
4. 部署时用 HTTPS 防止中间人攻击

---

💡 使用技巧

1. 离线模式：没有 API Key 也能玩，角色会用预设台词对话
2. 在线模式：配置 API Key 后，AI 实时生成对话，更有趣
3. 回合数设置：建议设 2 回合，太长角色会重复说话
4. 参与聊天：在输入框发言，角色会随机响应你
5. 导出记录：聊完后可以导出 txt 保存精彩对话

---

项目创建时间：2026年5月4日
最后更新：2026年5月4日
