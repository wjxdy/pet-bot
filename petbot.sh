#!/bin/bash
# PetBot 一键启动脚本
# 下载地址: https://github.com/wjxdy/pet-bot/releases/download/v1.1.0/petbot.sh

set -e

APP_NAME="PetBot"
APP_DIR="$HOME/.petbot"
VERSION="1.1.0"
DOWNLOAD_URL="https://github.com/wjxdy/pet-bot/releases/download/v${VERSION}/PetBot-v${VERSION}.zip"

echo "🚀 正在启动 ${APP_NAME}..."

# 创建应用目录
mkdir -p "${APP_DIR}"

# 检查是否已下载
if [ ! -d "${APP_DIR}/PetBot.app" ]; then
    echo "📥 首次运行，正在下载 ${APP_NAME}..."
    
    # 下载到临时文件
    TEMP_ZIP="/tmp/petbot_${VERSION}.zip"
    
    if command -v curl &> /dev/null; then
        curl -L --progress-bar "${DOWNLOAD_URL}" -o "${TEMP_ZIP}"
    elif command -v wget &> /dev/null; then
        wget --progress=bar:force "${DOWNLOAD_URL}" -O "${TEMP_ZIP}"
    else
        echo "❌ 错误: 需要 curl 或 wget 来下载"
        exit 1
    fi
    
    echo "📦 解压中..."
    unzip -q "${TEMP_ZIP}" -d "${APP_DIR}"
    rm -f "${TEMP_ZIP}"
    
    # 清除隔离属性（关键步骤）
    echo "🔓 移除安全限制..."
    xattr -cr "${APP_DIR}/PetBot.app" 2>/dev/null || true
    
    echo "✅ 下载完成"
fi

# 检查是否已在运行
if pgrep -x "PetBot" > /dev/null; then
    echo "⚠️  ${APP_NAME} 已经在运行"
    echo "   如需重启，请先运行: pkill -9 PetBot"
    exit 0
fi

# 启动应用
echo "🎯 启动 ${APP_NAME}..."
"${APP_DIR}/PetBot.app/Contents/MacOS/PetBot" &

sleep 2

# 检查是否启动成功
if pgrep -x "PetBot" > /dev/null; then
    echo "✅ ${APP_NAME} 启动成功!"
    echo ""
    echo "   💡 使用提示:"
    echo "      • 快捷键: Option + Space 打开输入框"
    echo "      • 菜单栏: PetBot 菜单中可以打开设置和历史记录"
    echo "      • 退出: 右键点击宠物选择退出，或 Cmd+Q"
else
    echo "❌ 启动失败"
    exit 1
fi
