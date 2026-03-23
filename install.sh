#!/bin/bash
# PetBot 一键下载启动脚本
# 用法: bash <(curl -s https://raw.githubusercontent.com/wjxdy/pet-bot/master/install.sh)
# 或保存为 install.sh 后运行: bash install.sh

set -e

APP_NAME="PetBot"
APP_DIR="$HOME/.petbot"
VERSION="1.1.0"
DOWNLOAD_URL="https://github.com/wjxdy/pet-bot/releases/download/v${VERSION}/PetBot-v${VERSION}.zip"

echo "🚀 PetBot 一键启动器"
echo "===================="
echo ""

# 检查系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 错误: PetBot 只支持 macOS"
    exit 1
fi

# 创建应用目录
mkdir -p "${APP_DIR}"

# 检查是否已安装
if [ ! -d "${APP_DIR}/PetBot.app" ]; then
    echo "📥 首次运行，正在下载 PetBot v${VERSION}..."
    echo "   下载地址: ${DOWNLOAD_URL}"
    echo ""
    
    TEMP_ZIP="/tmp/petbot_${VERSION}.zip"
    
    # 下载
    if command -v curl &> /dev/null; then
        curl -L --progress-bar "${DOWNLOAD_URL}" -o "${TEMP_ZIP}"
    elif command -v wget &> /dev/null; then
        wget --progress=bar:force "${DOWNLOAD_URL}" -O "${TEMP_ZIP}"
    else
        echo "❌ 错误: 需要 curl 或 wget 来下载"
        exit 1
    fi
    
    echo ""
    echo "📦 解压安装中..."
    unzip -q "${TEMP_ZIP}" -d "${APP_DIR}"
    rm -f "${TEMP_ZIP}"
    
    # 移除安全限制（关键步骤）
    echo "🔓 正在移除系统安全限制..."
    xattr -cr "${APP_DIR}/PetBot.app" 2>/dev/null || true
    
    echo ""
    echo "✅ 安装完成!"
    echo ""
else
    echo "📦 PetBot 已安装"
fi

# 显示安装位置
echo ""
echo "📁 安装位置: ${APP_DIR}"
echo "   可执行文件: ${APP_DIR}/PetBot.app/Contents/MacOS/PetBot"
echo "   启动脚本: ${APP_DIR}/petbot.sh"
echo ""

# 检查是否已在运行
if pgrep -x "PetBot" > /dev/null; then
    echo "⚠️  PetBot 已经在运行"
    echo ""
    echo "   提示: 如需重启，请运行: pkill -9 PetBot"
    exit 0
fi

# 启动应用
echo "🎯 启动 PetBot..."
"${APP_DIR}/PetBot.app/Contents/MacOS/PetBot" &

sleep 2

# 检查是否启动成功
if pgrep -x "PetBot" > /dev/null; then
    echo ""
    echo "✅ PetBot 启动成功!"
    echo ""
    echo "   💡 使用指南:"
    echo "      • 按 Option + Space 打开输入框"
    echo "      • 点击菜单栏的 PetBot 打开设置和历史记录"
    echo "      • 宠物可以拖动到桌面任意位置"
    echo ""
    echo "   📁 安装位置: ${APP_DIR}/PetBot.app"
    echo ""
else
    echo ""
    echo "❌ 启动失败"
    echo ""
    echo "   尝试手动运行:"
    echo "      ${APP_DIR}/PetBot.app/Contents/MacOS/PetBot"
    exit 1
fi
