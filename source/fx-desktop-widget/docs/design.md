# FX Desktop Widget Design

The widget combines historical exchange-rate context with an amount-based comparison in a small desktop interface. EUR/CNY is the initial currency pair, while the provider adapter supports other available pairs.

## Responsibilities

| Component | Responsibility |
| --- | --- |
| `index.html` and `src/styles.css` | Page structure and visual layout |
| `src/app.js` | User preferences, requests, caching, events, and SVG chart rendering |
| `src/fx-core.mjs` | Numeric bounds, date conversion, historical normalization, extremes, and comparisons |
| `electron/main.js` | Frameless, resizable, always-on-top window |
| `electron/preload.js` | Minimize and close bridge |
| `FxWidget.ps1` | Separate Windows PowerShell/WinForms implementation |

## Request and render flow

1. Restore the currency pair, amount, and lookback period from local storage.
2. Load the currency list, with a predefined list available if that request fails.
3. Read valid cache entries for the selected pair and request missing data.
4. Normalize history, find the minimum and maximum, and calculate the amount comparison.
5. Render the rate cards and SVG trend chart.
6. Save preference changes and refresh the selected pair periodically.

A monotonically increasing refresh identifier prevents an earlier request from rendering over a later currency selection. Changing only the amount recalculates the display using the data held in memory.

## Calculation convention

Let `A` be the budget in the quote currency, `R` the current reference rate, `L` the historical low, and `H` the historical high.

```text
receivedNow    = A / R
receivedAtLow  = A / L
receivedAtHigh = A / H

lossInQuote   = max(0, receivedAtLow - receivedNow) × R
savingInQuote = max(0, receivedNow - receivedAtHigh) × R
```

The historical comparisons are expressed in quote-currency units at rate `R`. The labels and formulas use the same convention when the currency pair changes.

## Data boundary

The current provider exposes three operations, `currencies()`, `latest(base, quote)`, and `history(base, quote, years)`. A future provider can implement the same operations, with normalization at the adapter boundary.

The quote cache lasts 60 seconds. History and the currency list use 12-hour caching. Expired entries are excluded by the cache reader, so reliable stale-data recovery remains an improvement to implement.

## Desktop boundary

Electron creates the desktop window with context isolation enabled and Node integration disabled. Window controls pass through the preload bridge. The interface and its calculation module can also run in a browser, independently of the desktop wrapper.

## Verification

The existing test file checks pure calculation behavior. Network failures, refresh races, installation, and the PowerShell application remain outside that suite.

[Back to setup](../README.md) · [Project overview](../../../projects/fx-widget.md)
