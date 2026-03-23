# PetBot 🤖

你的桌面 AI 宠物助手，支持多 Agent 切换，让 AI 助手像桌面宠物一样陪伴你工作。

![PetBot](PetBot/PetBot/Assets.xcassets/AppIcon.appiconset/icon_128x128.png)

## 🚀 一键启动

```bash
bash <(curl -s https://raw.githubusercontent.com/wjxdy/pet-bot/master/install.sh)
```

首次运行会自动下载并安装，之后直接启动。

## ✨ 功能特性

- 🤖 **多 Agent 支持** - 可在多个 AI 助手间自由切换
- 💬 **流式对话** - 打字机效果，实时显示 AI 回复
- 📝 **Markdown 渲染** - 支持代码块、列表、链接等富文本
- 📜 **历史记录** - 像素 RPG 风格的历史聊天窗口
- ⌨️ **全局快捷键** - Option + Space 快速打开输入框
- 🐱 **桌面宠物** - 可拖动到桌面任意位置

## 📦 安装方法

### 方法一：一键脚本（推荐）

```bash
bash <(curl -s https://raw.githubusercontent.com/wjxdy/pet-bot/master/install.sh)
```

### 方法二：手动下载

1. 下载最新版本：[Releases](https://github.com/wjxdy/pet-bot/releases)
2. 解压 `PetBot-v1.1.0.zip`
3. 运行 `./petbot.sh`

### 方法三：源码构建

```bash
git clone https://github.com/wjxdy/pet-bot.git
cd pet-bot/PetBot
swift build -c release
swift run
```

## 🎮 使用方法

| 操作 | 说明 |
|------|------|
| `Option + Space` | 打开/关闭输入框 |
| 拖动宠物 | 移动位置 |
| 右键宠物 | 菜单选项 |
| 菜单栏 PetBot | 设置、历史记录、关于 |
| `Cmd + Q` | 退出应用 |

## 🖼️ 界面预览

- **气泡对话** - 显示在宠物左上方，支持 Markdown
- **设置窗口** - 可配置自动消失时间、位置、Agent 选择
- **历史窗口** - 像素 RPG 风格，可查看所有聊天记录

## ❓ 常见问题

### Q: 安装后如何再次打开？

**A:** 有以下几种方式：

**方法 1：再次运行安装脚本（推荐）**
```bash
bash <(curl -s https://raw.githubusercontent.com/wjxdy/pet-bot/master/install.sh)
```
脚本会检测到已安装，直接启动。

**方法 2：直接运行本地脚本**
```bash
~/.petbot/petbot.sh
```

**方法 3：直接运行可执行文件**
```bash
~/.petbot/PetBot.app/Contents/MacOS/PetBot
```

**方法 4：从 Applications 启动（如果手动移动过）**
```bash
open /Applications/PetBot.app
```

### Q: 找不到 ~/.petbot 文件夹？

**A:** 这是一个隐藏文件夹（以点开头的都是隐藏文件夹）。在 Finder 中按 `Cmd + Shift + .` 可以显示隐藏文件。

或者直接在终端运行：
```bash
ls -la ~/.petbot
```

### Q: 提示"App 已损坏"怎么办？

**A:** 这是 macOS 的安全机制。运行以下命令：
```bash
xattr -cr ~/.petbot/PetBot.app
```
然后重新启动。

### Q: 如何修改 OpenClaw 路径？

**A:** 
1. 打开 PetBot 设置（菜单栏 → PetBot → 设置...）
2. 修改 "OpenClaw 路径" 为实际安装位置
3. 常见路径：`~/.openclaw`、`/usr/local`、`/opt/homebrew`

## 📝 更新日志

### v1.1.0 (2026-03-23)

#### 修复
- ✅ 菜单栏中文显示问题
- ✅ 设置窗口和历史消息窗口可正常打开
- ✅ 设置窗口滚动条修复

#### 改进
- ✅ 精简脚本，只保留 start.sh、stop.sh、petbot.sh、install.sh
- ✅ 使用 main.swift 入口点替代 SwiftUI App 协议
- ✅ 添加一键安装脚本

### v1.0.0 (2026-03-21)

- 🎉 初始版本发布
- 气泡框流式输出
- 历史聊天记录
- Markdown 渲染
- 多 Agent 切换

## 🛠️ 技术栈

- **语言**: Swift 5.9
- **框架**: AppKit, SwiftUI
- **最低系统**: macOS 14.0 (Sonoma)
- **架构**: Apple Silicon (arm64)

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🙏 致谢

感谢所有测试和反馈的用户！
