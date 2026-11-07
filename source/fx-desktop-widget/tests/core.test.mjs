import assert from "node:assert/strict";
import {
  calculateComparison,
  clampNumber,
  minMax,
  normalizeHistory,
  toIsoDate
} from "../src/fx-core.mjs";

assert.equal(toIsoDate(new Date("2026-05-24T12:30:00.000Z")), "2026-05-24");

assert.equal(clampNumber("5", 1, 30, 1), 5);
assert.equal(clampNumber("-2", 1, 30, 1), 1);
assert.equal(clampNumber("99", 1, 30, 1), 30);
assert.equal(clampNumber("x", 1, 30, 7), 7);

const history = normalizeHistory(
  {
    "2024-01-02": { CNY: 7.7 },
    "2024-01-01": { CNY: 7.8 },
    "2024-01-03": { USD: 1.1 }
  },
  "CNY"
);

assert.deepEqual(history, [
  { date: "2024-01-01", rate: 7.8 },
  { date: "2024-01-02", rate: 7.7 }
]);

assert.deepEqual(minMax(history), {
  low: { date: "2024-01-02", rate: 7.7 },
  high: { date: "2024-01-01", rate: 7.8 }
});

const comparison = calculateComparison({
  amount: 10000,
  currentRate: 8,
  lowRate: 7.5,
  highRate: 8.5
});

assert.equal(Number(comparison.receivedNow.toFixed(4)), 1250);
assert.equal(Number(comparison.lossInQuote.toFixed(2)), 666.67);
assert.equal(Number(comparison.savingInQuote.toFixed(2)), 588.24);

console.log("core tests passed");
