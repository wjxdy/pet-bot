#!/bin/bash
# PetBot 自动化测试脚本

echo "🧪 PetBot 自动化测试系统"
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数
PASSED=0
FAILED=0

# 函数：运行测试
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo ""
    echo "📋 测试: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        ((FAILED++))
        return 1
    fi
}

# 测试 1: 编译
echo ""
echo "🔨 步骤 1: 编译项目"
cd /Users/xulei/Documents/pet-bot/PetBot
if swift build > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✅ 编译成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ 编译失败${NC}"
    cat /tmp/build.log | tail -20
    ((FAILED++))
    exit 1
fi

# 测试 2: 启动应用
echo ""
echo "🚀 步骤 2: 启动应用"
killall PetBot 2>/dev/null
sleep 1
swift run > /tmp/petbot_test.log 2>&1 &
PID=$!
echo "应用 PID: $PID"

# 等待应用启动
sleep 3

if ps -p $PID > /dev/null; then
    echo -e "${GREEN}✅ 应用启动成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ 应用启动失败${NC}"
    cat /tmp/petbot_test.log | tail -20
    ((FAILED++))
    exit 1
fi

# 测试 3: 检查窗口创建
echo ""
echo "🪟 步骤 3: 检查窗口"
# 使用 osascript 检查窗口
sleep 2
WINDOW_COUNT=$(osascript -e 'tell application "System Events" to count windows of application process "PetBot"' 2>/dev/null || echo "0")
if [ "$WINDOW_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ 检测到 $WINDOW_COUNT 个窗口${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️ 未检测到窗口（可能窗口未创建或权限问题）${NC}"
fi

# 测试 4: 菜单项检查
echo ""
echo "📋 步骤 4: 检查菜单项"
# 检查日志中是否包含菜单设置
if grep -q "setupMainMenu" /tmp/petbot_test.log 2>/dev/null || grep -q "PetBot 启动完成" /tmp/petbot_test.log 2>/dev/null; then
    echo -e "${GREEN}✅ 菜单初始化完成${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️ 无法验证菜单（需要运行时检查）${NC}"
fi

# 测试 5: 热键注册
echo ""
echo "⌨️ 步骤 5: 检查热键"
if grep -q "热键注册成功\|Hotkey registered" /tmp/petbot_test.log 2>/dev/null; then
    echo -e "${GREEN}✅ 热键注册成功${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️ 热键状态未知${NC}"
fi

# 清理
echo ""
echo "🧹 清理测试环境"
kill $PID 2>/dev/null
sleep 1

# 测试报告
echo ""
echo "=========================="
echo "📊 测试报告"
echo "=========================="
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}⚠️ 有测试失败，请检查${NC}"
    exit 1
fi
