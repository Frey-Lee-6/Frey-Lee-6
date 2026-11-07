export function toIsoDate(date) {
  return date.toISOString().slice(0, 10);
}

export function clampNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.max(min, Math.min(max, number));
}

export function minMax(points) {
  if (!Array.isArray(points) || points.length === 0) {
    return { low: null, high: null };
  }

  return points.reduce(
    (acc, point) => {
      if (!acc.low || point.rate < acc.low.rate) acc.low = point;
      if (!acc.high || point.rate > acc.high.rate) acc.high = point;
      return acc;
    },
    { low: null, high: null }
  );
}

export function calculateComparison({ amount, currentRate, lowRate, highRate }) {
  const receivedNow = amount / currentRate;
  const receivedAtLow = amount / lowRate;
  const receivedAtHigh = amount / highRate;

  return {
    receivedNow,
    receivedAtLow,
    receivedAtHigh,
    lossInQuote: Math.max(0, receivedAtLow - receivedNow) * currentRate,
    savingInQuote: Math.max(0, receivedNow - receivedAtHigh) * currentRate
  };
}

export function normalizeHistory(rates, quote) {
  return Object.entries(rates)
    .filter(([, row]) => Number.isFinite(Number(row[quote])))
    .map(([date, row]) => ({ date, rate: Number(row[quote]) }))
    .sort((a, b) => a.date.localeCompare(b.date));
}

