# FX Desktop Widget

Compare a currency pair's latest available reference rate with historical highs and lows, then see how those rates affect an exchange amount.

**JavaScript · Electron · Windows PowerShell**

[Project overview](../../projects/fx-widget.md) · [Technical design](docs/design.md) · [Core tests](tests/core.test.mjs)

## What you can do

- Choose a base and quote currency, with EUR/CNY as the default.
- Inspect historical extremes and the dates on which they occurred.
- Compare the amount received at the current, lowest, and highest rates.
- Change the lookback period and exchange amount.
- Keep preferences between sessions in the web/Electron implementation.
- Run an Electron desktop window or the included Windows PowerShell implementation.

## Choose a launch mode

| Mode | Requirements | Entry point |
| --- | --- | --- |
| Electron desktop | Node.js and npm, internet access for dependencies and rates | `npm start` after installation |
| Browser preview | Node.js and npm | `npm run serve` |
| Windows PowerShell | Windows with Windows PowerShell and WinForms | `StartFxWidget.bat` |
| Windows shortcut installation | Same requirements as the PowerShell mode | `InstallFxWidget.bat` |

The Electron application uses the HTML/JavaScript interface. The PowerShell application is a separate implementation in `FxWidget.ps1`.

## Quick start

```sh
git clone https://github.com/Frey-Lee-6/Frey-Lee-6.git
cd Frey-Lee-6/source/fx-desktop-widget
npm install
npm start
```

The package declares Electron 31 and http-server 14 as development dependencies. Use a Node.js environment compatible with those packages.

For a browser preview, run the following command from the same directory.

```sh
npm run serve
```

Open `http://127.0.0.1:4173`. The window minimize and close buttons are available when the page runs inside Electron.

### Windows launcher and shortcuts

Double-click `StartFxWidget.bat` to start the PowerShell application. Its dependencies are separate from npm.

To add a desktop shortcut, run `InstallFxWidget.bat`. The installer copies the widget to `%LOCALAPPDATA%\FxDesktopWidget` and creates a desktop shortcut. Use `UninstallFxWidget.bat` to remove that installation.

## Understanding the calculation

The exchange rate represents quote-currency units per base-currency unit. The entered amount is a budget in the quote currency.

```text
base currency received = quote-currency budget / exchange rate
```

For an illustrative EUR/CNY comparison used by the tests, a 10,000 CNY budget at a rate of 8 buys 1,250 EUR. The low/high comparison values express differences in the base currency received, converted back to the quote currency at the current rate.

The implementation is in [fx-core.mjs](src/fx-core.mjs).

## Code layout

```text
fx-desktop-widget/
├── index.html              Page structure
├── src/
│   ├── app.js              State, requests, events, and rendering
│   ├── fx-core.mjs         Calculation and normalization functions
│   └── styles.css          Widget styling
├── electron/
│   ├── main.js             Desktop window
│   └── preload.js          Window-control bridge
├── tests/core.test.mjs     Calculation tests
├── FxWidget.ps1            Windows PowerShell implementation
├── StartFxWidget.bat       PowerShell launcher
├── InstallFxWidget.bat     Desktop shortcut installation
└── docs/design.md          Data flow and calculation details
```

## Run the tests

```sh
npm test
```

Expected output includes `core tests passed`. The tests cover ISO date formatting, numeric bounds and fallbacks, historical-rate normalization, minimum/maximum selection, and the exchange comparison calculation.

These tests have passed during portfolio preparation. Live API behavior, Electron packaging, and Windows installation require separate end-to-end checks.

## Data and caching

The provider adapter in `src/app.js` calls Frankfurter for currencies, latest rates, and historical rates. Quotes are cached for 60 seconds, while history and currency-list data use a 12-hour cache. Preferences and cached values are stored in `localStorage`.

Expired data is not a reliable offline fallback in the current implementation. If data requests fail, the interface reports the failure. Live data availability depends on the provider.

The data source supplies reference rates. Refreshing the interface every minute does not imply minute-by-minute changes in those rates. [Frankfurter documentation](https://frankfurter.dev/)

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Dependencies are missing | Run `npm install` inside this directory. |
| No exchange rate appears | Choose two different currencies and check access to the rate provider. |
| A local-file preview fails | Use the HTTP preview command instead of opening `index.html` directly. |
| PowerShell mode cannot start | Confirm Windows PowerShell is installed and review the launcher output. |
| Labels appear in Chinese | The web UI currently uses Chinese labels. The PowerShell implementation has a language toggle. |
