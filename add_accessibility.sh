#!/bin/bash
# 添加 PetBot 到辅助功能权限

echo "正在添加 PetBot 到辅助功能权限..."

# 应用路径
APP_PATH="/Users/xulei/Documents/pet-bot/PetBot/.build/arm64-apple-macosx/debug/PetBot"

# 使用 tccutil 重置（如果之前有加过）
tccutil reset Accessibility com.petbot.PetBot 2>/dev/null

# 提示用户手动添加
echo ""
echo "请按以下步骤手动添加："
echo ""
echo "1. 打开 系统设置 → 隐私与安全性 → 辅助功能"
echo ""
echo "2. 点击左下角的 '+' 按钮"
echo ""
echo "3. 按 Cmd+Shift+G 输入："
echo "   /Users/xulei/Documents/pet-bot/PetBot/.build/arm64-apple-macosx/debug"
echo ""
echo "4. 选择 PetBot 文件，点击 打开"
echo ""
echo "5. 确保 PetBot 旁边的开关是打开的 ✅"
echo ""
echo "添加完成后，重新运行 PetBot："
echo "   cd ~/Documents/pet-bot/PetBot && swift run"
echo ""

# 打开系统设置
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
