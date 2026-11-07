# 汇率桌面插件设计

这是一个 Windows 桌面小组件原型，默认显示 `EUR/CNY`，并支持切换任意 Frankfurter 覆盖的币种。

## 已实现

- 实时汇率卡片：显示 `1 基础币种 = N 报价币种`。
- 近 N 年最高点 / 最低点：按历史日频数据计算。
- 兑换损益对比：默认按“用报价币种买基础币种”计算。`EUR/CNY` 时就是“用人民币买欧元”。
- 任意币种切换：币种列表来自 Frankfurter `/currencies`。
- 设置记忆与本地缓存：重启后保留币种、N 年、金额；网络短暂失败时可使用未过期缓存。
- Windows 窗口控制：Electron 模式支持拖动、最小化、关闭和置顶。
- 数据源抽象：`src/app.js` 的 `providers` 对象可以继续添加 OANDA、Wise、ExchangeRate-API 等实时源。
- Electron 外壳：安装依赖后可作为 Windows 悬浮窗口运行。

## 运行

最简单方式：双击 `启动汇率插件.bat`。这是免安装 Windows 桌面版，不需要 npm，也不需要 Electron，启动后不会保留命令窗口。

想让它像普通软件一样出现在桌面：双击 `InstallFxWidget.bat` 或 `安装到桌面.bat`。它会把程序复制到 `%LOCALAPPDATA%\FxDesktopWidget`，并在桌面创建 `FX Desktop Widget` 快捷方式。以后直接双击桌面图标即可，启动时不会出现命令窗口。

发给别人使用：把这个文件夹发给对方，让对方双击 `InstallFxWidget.bat`。卸载时双击 `UninstallFxWidget.bat`。

如果只想预览网页版本：双击 `预览网页版本.bat`，然后打开 `http://127.0.0.1:4173/index.html`。

说明：免安装桌面版使用 Windows PowerShell / WinForms，默认中文界面，右上角 `EN` 按钮可以切换英文。

直接打开 `index.html` 可以预览。如果浏览器限制本地请求，可以启动本地服务：

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

或者使用 npm 脚本：

```powershell
npm install
npm run serve
```

桌面窗口模式：

```powershell
npm install
npm start
```

验证核心计算：

```powershell
npm test
```

## 数据说明

默认使用 Frankfurter。它是免费、免 API key 的汇率 API，适合第一版验证和历史区间计算，但它不是秒级银行报价；如果需要真正交易级实时价，可以在 `providers` 中增加付费实时报价源，并保持 UI 与计算逻辑不变。
