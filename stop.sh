#!/bin/bash
# 退出 PetBot 应用

echo "正在关闭 PetBot..."

# 强制关闭所有 PetBot 进程
killall -9 PetBot 2>/dev/null

# 确认已关闭
sleep 1
if ps aux | grep -v grep | grep -q PetBot; then
    echo "❌ 关闭失败，请手动关闭"
    exit 1
else
    echo "✅ PetBot 已关闭"
fi
