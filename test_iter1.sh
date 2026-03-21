#!/bin/bash
# PetBot 迭代 1 测试脚本
# 测试内容：输入框焦点、气泡窗口、设置窗口

set -e

APP_DIR="/Users/xulei/Documents/pet-bot/PetBot"
LOG_FILE="/tmp/petbot_test.log"
PID_FILE="/tmp/petbot_test.pid"

echo "🧪 PetBot 迭代 1 测试开始"
echo "========================"

# 1. 编译测试
echo ""
echo "[1/4] 编译测试..."
cd "$APP_DIR"
if swift build > /tmp/petbot_build.log 2>&1; then
    echo "✅ 编译通过"
else
    echo "❌ 编译失败"
    tail -20 /tmp/petbot_build.log
    exit 1
fi

# 2. 启动应用
echo ""
echo "[2/4] 启动应用..."
killall PetBot 2> /dev/null || true
sleep 1
swift run > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
sleep 3

if pgrep -x "PetBot" > /dev/null; then
    echo "✅ 应用启动成功 (PID: $(cat $PID_FILE))"
else
    echo "❌ 应用启动失败"
    tail -20 "$LOG_FILE"
    exit 1
fi

# 3. 功能检查
echo ""
echo "[3/4] 功能检查..."

# 检查日志中是否有错误
if grep -i "error\|fatal\|crash" "$LOG_FILE" 2> /dev/null; then
    echo "⚠️  发现错误日志："
    grep -i "error\|fatal\|crash" "$LOG_FILE" | head -5
else
    echo "✅ 无错误日志"
fi

# 4. 手动测试提示
echo ""
echo "[4/4] 手动测试步骤"
echo "===================="
echo ""
echo "请按以下步骤测试："
echo ""
echo "📝 测试 1: 输入框焦点"
echo "   1. 按 Option + Space 唤出输入框"
echo "   2. 检查是否自动获得焦点（看到光标）"
echo "   3. 尝试输入文字"
echo "   4. 按回车发送消息"
echo "   ✅ 通过标准：能输入文字并发送"
echo ""
echo "💬 测试 2: 气泡窗口"
echo "   1. 发送一条消息"
echo "   2. 检查气泡窗口是否显示"
echo "   3. 检查气泡内容是否正确（不是空的）"
echo "   4. 检查气泡位置（应在宠物上方）"
echo "   ✅ 通过标准：气泡显示正确内容"
echo ""
echo "⚙️  测试 3: 设置窗口"
echo "   1. 点击菜单栏 PetBot → 设置"
echo "   2. 检查窗口是否显示"
echo "   3. 检查内容是否显示（气泡设置、Agent选择）"
echo "   4. 尝试切换 Agent"
echo "   ✅ 通过标准：设置选项正常显示和操作"
echo ""
echo "测试完成后，请输入结果："
echo "  all-pass  - 所有测试通过"
echo "  fail-X    - 测试 X 失败（如 fail-1）"
echo ""

# 等待用户输入
echo "等待测试结果..."

# 保持进程运行
tail -f "$LOG_FILE" &
TAIL_PID=$!

# 捕获退出信号清理
cleanup() {
    echo ""
    echo "🧹 清理测试环境..."
    kill $TAIL_PID 2> /dev/null || true
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2> /dev/null || true
    fi
    echo "✅ 测试结束"
}
trap cleanup EXIT

# 等待中断
wait
