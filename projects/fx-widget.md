# 桌面汇率组件

在 Windows 桌面查看实时汇率并比较历史汇率。工程包含 Electron 界面、独立的汇率处理模块和 PowerShell 启动脚本。

**技术栈** Electron、JavaScript、PowerShell。

**验证** 汇率核心逻辑测试已通过。

[浏览源码与运行说明](../source/fx-desktop-widget)

## 运行方式

- Windows 免安装版可用 `StartFxWidget.bat` 启动。
- Electron 版在项目目录运行 `npm install` 和 `npm start`。
- 核心计算测试使用 `npm test`。汇率取自 Frankfurter 的最新可用参考数据，刷新频率取决于数据源。
