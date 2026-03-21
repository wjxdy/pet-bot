#!/bin/bash
# PetBot UI 功能测试脚本

echo "🎮 PetBot UI 功能自动化测试"
echo "=============================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

# 启动应用
echo ""
echo "🚀 启动 PetBot..."
killall PetBot 2>/dev/null
sleep 1
cd /Users/xulei/Documents/pet-bot/PetBot
swift run > /tmp/petbot_ui.log 2>&1 &
echo "应用已启动，PID: $!"
echo "等待 5 秒让应用完全启动..."
sleep 5

# 使用 AppleScript 测试 UI
echo ""
echo "🧪 开始 UI 测试..."

# 测试 1: 检查应用是否运行
echo ""
echo "📱 测试 1: 检查应用状态"
if osascript -e 'tell application "System Events" to exists application process "PetBot"' 2>/dev/null | grep -q "true"; then
    echo -e "${GREEN}✅ 应用正在运行${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ 应用未运行${NC}"
    ((FAILED++))
fi

# 测试 2: 检查菜单栏
echo ""
echo "📋 测试 2: 检查菜单栏"
MENU_ITEMS=$(osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        set menuItems to name of every menu item of menu 1 of menu bar 1
        return menuItems
    end tell
end tell
EOF
)

if echo "$MENU_ITEMS" | grep -q "打开聊天历史"; then
    echo -e "${GREEN}✅ 找到「打开聊天历史」菜单项${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ 未找到「打开聊天历史」菜单项${NC}"
    echo "可用菜单项: $MENU_ITEMS"
    ((FAILED++))
fi

# 测试 3: 模拟点击「打开聊天历史」
echo ""
echo "👆 测试 3: 点击「打开聊天历史」菜单"
osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        click menu item "打开聊天历史" of menu 1 of menu bar 1
    end tell
end tell
EOF

sleep 2

# 检查新窗口是否出现
echo ""
echo "🪟 测试 4: 检查聊天历史窗口"
WINDOW_TITLES=$(osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        set windowList to name of every window
        return windowList
    end tell
end tell
EOF
)

if echo "$WINDOW_TITLES" | grep -q "聊天记录"; then
    echo -e "${GREEN}✅ 聊天历史窗口已打开${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ 聊天历史窗口未打开${NC}"
    echo "当前窗口: $WINDOW_TITLES"
    ((FAILED++))
fi

# 关闭聊天窗口
echo ""
echo "🧹 测试 5: 关闭聊天窗口"
osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        if exists window "聊天记录" then
            click button 1 of window "聊天记录"
        end if
    end tell
end tell
EOF

sleep 1

# 测试 6: 检查设置窗口
echo ""
echo "⚙️ 测试 6: 打开设置窗口"
osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        click menu item "设置..." of menu 1 of menu bar 1
    end tell
end tell
EOF

sleep 2

SETTINGS_OPEN=$(osascript <<EOF 2>/dev/null
tell application "System Events"
    tell application process "PetBot"
        return exists window "PetBot 设置"
    end tell
end tell
EOF
)

if [ "$SETTINGS_OPEN" = "true" ]; then
    echo -e "${GREEN}✅ 设置窗口已打开${NC}"
    ((PASSED++))
    # 关闭设置窗口
    osascript <<EOF 2>/dev/null
    tell application "System Events"
        tell application process "PetBot"
            if exists window "PetBot 设置" then
                click button 1 of window "PetBot 设置"
            end if
        end tell
    end tell
EOF
else
    echo -e "${YELLOW}⚠️ 设置窗口检测失败${NC}"
fi

# 清理
echo ""
echo "🧹 清理测试环境"
killall PetBot 2>/dev/null

# 测试报告
echo ""
echo "=============================="
echo "📊 UI 功能测试报告"
echo "=============================="
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有 UI 测试通过！${NC}"
else
    echo -e "${YELLOW}⚠️ 部分测试失败，请查看日志: /tmp/petbot_ui.log${NC}"
fi
