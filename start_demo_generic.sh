#!/bin/bash

echo "🚀 启动DocumentDB DMS演示服务器"
echo "================================"

# 检查必要文件
if [ ! -f "dms_server_correct.py" ]; then
    echo "❌ 找不到 dms_server_correct.py 文件"
    exit 1
fi

if [ ! -f "global-bundle.pem" ]; then
    echo "❌ 找不到 global-bundle.pem 证书文件"
    echo "请从AWS下载DocumentDB证书文件"
    exit 1
fi

# 停止现有服务
echo "📋 停止现有服务..."
pkill -f "python.*dms_server" 2>/dev/null

# 清理端口
echo "🔧 清理端口3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null

# 启动服务器
echo "🔧 启动DMS演示服务器..."
python3 dms_server_correct.py > server.log 2>&1 &

# 等待服务启动
sleep 3

# 检查服务状态
if pgrep -f "python.*dms_server" > /dev/null; then
    PID=$(pgrep -f "python.*dms_server")
    echo "✅ 服务器启动成功! PID: $PID"
    echo "📱 本地访问: http://localhost:3000"
    echo ""
    echo "📝 查看日志: tail -f server.log"
    echo "🛑 停止服务: pkill -f python3"
    echo ""
    echo "🌐 正在打开浏览器..."
    open http://localhost:3000 2>/dev/null || echo "请手动打开浏览器访问: http://localhost:3000"
else
    echo "❌ 服务器启动失败，请检查日志:"
    tail -10 server.log
    exit 1
fi