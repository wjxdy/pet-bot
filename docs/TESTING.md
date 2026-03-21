# PetBot 自动化测试系统

## 🎯 目标
全自动测试 PetBot 功能，无需用户手动操作

## 📁 测试脚本

### 1. 基础测试 (`test_automation.sh`)
测试编译、启动、窗口创建等基础功能

```bash
cd /Users/xulei/Documents/pet-bot
./test_automation.sh
```

### 2. UI 功能测试 (`test_ui.sh`)
测试菜单、窗口交互等 UI 功能

```bash
cd /Users/xulei/Documents/pet-bot
./test_ui.sh
```

**注意**: UI 测试需要授予「辅助功能」权限

## 🔐 权限设置

UI 测试需要控制你的电脑，请授予权限：

1. 打开「系统设置」→「隐私与安全性」→「辅助功能」
2. 添加「终端」(Terminal) 或你使用的命令行工具
3. 授予权限

## 🚀 全自动测试流程

```bash
# 一键运行所有测试
cd /Users/xulei/Documents/pet-bot
./test_automation.sh && ./test_ui.sh
```

## 📊 测试覆盖

### ✅ 已实现
- [x] 项目编译
- [x] 应用启动
- [x] 窗口创建
- [x] 菜单栏检测
- [x] 聊天历史窗口打开
- [x] 设置窗口打开

### 🔄 待实现
- [ ] 气泡窗口测试
- [ ] 输入框功能测试
- [ ] Agent 切换测试
- [ ] 消息发送测试
- [ ] 热键测试

## 📝 使用方法

### 开发人员（我）
1. 编写新功能代码
2. 提交到 GitHub
3. 运行自动化测试
4. 向你汇报结果

### 用户（你）
1. 接收功能完成通知
2. 确认是否需要调整
3. 提供反馈

## 🔧 扩展测试

添加新测试：

```bash
# 编辑 test_ui.sh
# 在文件中添加新的测试函数
```

示例测试函数：
```bash
test_new_feature() {
    echo ""
    echo "🆕 测试新功能"
    # 执行测试
    if some_command; then
        echo -e "${GREEN}✅ 通过${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ 失败${NC}"
        ((FAILED++))
    fi
}
```

## 📞 反馈

测试失败时，我会收到通知并修复。

你也可以运行：
```bash
tail -f /tmp/petbot_ui.log
```
查看实时日志
