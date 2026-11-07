# Windows 汇率桌面插件设计

## 目标

做一个小而常驻的 Windows 桌面汇率插件，第一版聚焦 `EUR/CNY`，同时为任意币种对、不同数据源、提醒策略和打包发布留下接口。

## 核心界面

1. 顶部：当前币种对、刷新按钮、数据源状态。
2. 主汇率：`1 基础币种 = N 报价币种`，例如 `1 EUR = 7.82 CNY`。
3. 参数区：基础币种、报价币种、近 N 年、兑换金额。
4. 历史区：近 N 年最低点、最高点、对应日期。
5. 损益区：用报价币种买基础币种时，当前汇率相对历史最低点少得多少、相对历史最高点多得多少，并折算回报价币种。
6. 迷你趋势图：用于快速感知当前点位处在历史区间的高位还是低位。
7. 窗口控制：无边框置顶窗口，顶部可拖动，右上角提供刷新、最小化、关闭。

## 计算口径

以 `EUR/CNY` 为例，汇率 `rate` 表示 `1 EUR = rate CNY`。用户输入 `amount` 表示准备用多少 CNY 买 EUR。

- 当前可买欧元：`amount / currentRate`
- 历史最低点可买欧元：`amount / lowRate`
- 历史最高点可买欧元：`amount / highRate`
- 相比最低点少得的价值：`(amount / lowRate - amount / currentRate) * currentRate`
- 相比最高点多得的价值：`(amount / currentRate - amount / highRate) * currentRate`

当切换到其他币种对时，同一逻辑仍成立：永远用“报价币种”购买“基础币种”。

## 架构

- `index.html`：插件页面骨架。
- `src/styles.css`：桌面小组件视觉样式。
- `src/app.js`：状态、数据源、历史极值、损益计算和图表渲染。
- `electron/main.js`：Windows 悬浮窗口外壳。
- `providers`：数据源适配层。当前只有 `frankfurter`，以后可以增加真正秒级源。
- `localStorage`：保存用户设置与短期汇率缓存，减少重复请求。
- `src/fx-core.mjs`：纯计算函数，便于做自动化测试。

## 未来扩展

- 任意币种：现在已经通过远端 `/currencies` 动态拉取，UI 无需改动。
- 多数据源：新增 provider，只要实现 `latest(base, quote)`、`history(base, quote, years)`、`currencies()`。
- 桌面体验：增加拖拽、吸边、置顶开关、开机启动、系统托盘。
- 风险提醒：支持接近 N 年高点/低点时弹通知。
- 本地缓存：缓存历史数据，减少启动等待并支持离线展示上次结果。
