#!/bin/bash
# PetBot 启动脚本

cd "$(dirname "$0")/PetBot"

echo "🔨 构建 PetBot..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功，启动 PetBot..."
    swift run
else
    echo "❌ 构建失败"
    exit 1
fi
