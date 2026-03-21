# PetBot

你的 macOS 桌面 AI 宠物，支持多 Agent 切换。

## 功能

- 🐱 桌面悬浮宠物，可拖动
- ⌨️ 全局快捷键唤起对话（⌘+Option+Space）
- 🤖 多 Agent 切换（神农/主助手/搜索专家/Claude）
- 💬 气泡对话框显示 AI 回复
- ✨ 宠物状态动画（待机/倾听/思考/说话）

## 运行

```bash
cd PetBot
swift build
swift run
```

## 打包

```bash
swift build -c release
```

## 权限

首次运行需在 **系统设置 → 隐私与安全性 → 辅助功能** 中授权，以使用全局快捷键。

## 配置

编辑 `Models/Agent.swift` 添加自定义 Agent。
