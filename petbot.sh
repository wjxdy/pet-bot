#!/bin/bash
# PetBot 控制脚本

APP_DIR="/Users/xulei/Documents/pet-bot/PetBot"
PID_FILE="/tmp/petbot.pid"

show_help() {
    echo "用法: ./petbot.sh [命令]"
    echo ""
    echo "命令:"
    echo "  start    启动 PetBot"
    echo "  stop     停止 PetBot"
    echo "  restart  重启 PetBot"
    echo "  status   查看状态"
    echo "  log      查看日志"
    echo "  build    编译应用"
}

start_bot() {
    if pgrep -x "PetBot" > /dev/null; then
        echo "⚠️  PetBot 已经在运行"
        return 1
    fi
    
    echo "正在启动 PetBot..."
    cd "$APP_DIR" || exit 1
    
    swift build > /tmp/petbot_build.log 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败"
        cat /tmp/petbot_build.log
        return 1
    fi
    
    swift run > /tmp/petbot.log 2>&1 &
echo $! > "$PID_FILE"
    
    sleep 2
    
    if pgrep -x "PetBot" > /dev/null; then
        echo "✅ PetBot 启动成功!"
        echo "   快捷键: Option + Space"
    else
        echo "❌ 启动失败"
        return 1
    fi
}

stop_bot() {
    echo "正在停止 PetBot..."
    killall -9 PetBot 2>/dev/null
    sleep 1
    
    if pgrep -x "PetBot" > /dev/null; then
        echo "❌ 停止失败"
        return 1
    else
        echo "✅ PetBot 已停止"
        rm -f "$PID_FILE"
    fi
}

restart_bot() {
    stop_bot
    sleep 1
    start_bot
}

show_status() {
    if pgrep -x "PetBot" > /dev/null; then
        PID=$(pgrep -x "PetBot")
        echo "✅ PetBot 正在运行 (PID: $PID)"
    else
        echo "❌ PetBot 未运行"
    fi
}

show_log() {
    if [ -f /tmp/petbot.log ]; then
        tail -f /tmp/petbot.log
    else
        echo "暂无日志文件"
    fi
}

build_bot() {
    echo "正在编译 PetBot..."
    cd "$APP_DIR" || exit 1
    swift build 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 编译成功"
    else
        echo "❌ 编译失败"
        return 1
    fi
}

# 主命令
case "${1:-start}" in
    start)
        start_bot
        ;;
    stop)
        stop_bot
        ;;
    restart)
        restart_bot
        ;;
    status)
        show_status
        ;;
    log)
        show_log
        ;;
    build)
        build_bot
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        show_help
        exit 1
        ;;
esac
