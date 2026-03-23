#!/bin/bash
# PetBot 启动器（与 App 打包在一起）
# 用法: ./petbot.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${SCRIPT_DIR}/PetBot.app"
APP_NAME="PetBot"

echo "🚀 正在启动 ${APP_NAME}..."

# 检查 App 是否存在
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ 错误: 找不到 ${APP_PATH}"
    echo "   请确保 petbot.sh 和 PetBot.app 在同一目录"
    exit 1
fi

# 检查是否已在运行
if pgrep -x "PetBot" > /dev/null; then
    echo "⚠️  ${APP_NAME} 已经在运行"
    echo "   如需重启，请先运行: pkill -9 PetBot"
    exit 0
fi

# 移除安全限制（关键步骤）
echo "🔓 正在移除安全限制..."
xattr -cr "${APP_PATH}" 2>/dev/null || true

# 启动应用
echo "🎯 启动 ${APP_NAME}..."
"${APP_PATH}/Contents/MacOS/PetBot" &

sleep 2

# 检查是否启动成功
if pgrep -x "PetBot" >/dev/null; then
    echo "✅ ${APP_NAME} 启动成功!"
    echo ""
    echo "   💡 使用提示:"
    echo "      • 快捷键: Option + Space 打开输入框"
    echo "      • 菜单栏: 点击 PetBot 菜单打开设置和历史记录"
    echo "      • 退出: 点击宠物右键菜单或按 Cmd+Q"
else
    echo "❌ 启动失败"
    exit 1
fi
