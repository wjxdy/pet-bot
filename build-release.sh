#!/bin/bash
# PetBot 发布构建脚本

cd "$(dirname "$0")/PetBot"

echo "🔨 构建 Release 版本..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "可执行文件位置："
    echo "  .build/release/PetBot"
    echo ""
    echo "运行方式："
    echo "  ./.build/release/PetBot"
else
    echo "❌ 构建失败"
    exit 1
fi
