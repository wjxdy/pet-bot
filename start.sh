#!/bin/bash
# 启动 PetBot 应用

APP_DIR="/Users/xulei/Documents/pet-bot/PetBot"
PID_FILE="/tmp/petbot.pid"

echo "正在启动 PetBot..."

# 检查是否已经在运行
if pgrep -x "PetBot" > /dev/null; then
    echo "⚠️  PetBot 已经在运行"
    echo "如需重启，请先运行: ./stop.sh"
    exit 1
fi

# 进入应用目录
cd "$APP_DIR" || exit 1

# 编译并运行
swift build > /tmp/petbot_build.log 2>&1
if [ $? -ne 0 ]; then
    echo "❌ 编译失败，请检查 /tmp/petbot_build.log"
    exit 1
fi

# 后台运行
swift run > /tmp/petbot.log 2>&1 &
echo $! > "$PID_FILE"

sleep 2

# 检查是否启动成功
if pgrep -x "PetBot" > /dev/null; then
    echo "✅ PetBot 启动成功!"
    echo "   快捷键: Option + Space"
    echo "   日志: tail -f /tmp/petbot.log"
else
    echo "❌ 启动失败，请检查 /tmp/petbot.log"
    exit 1
fi
