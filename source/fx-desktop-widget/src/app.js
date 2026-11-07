import {
  calculateComparison,
  clampNumber,
  minMax,
  normalizeHistory,
  toIsoDate
} from "./fx-core.mjs";

const apiBase = "https://api.frankfurter.app";
const settingsKey = "fx-widget-settings-v1";
const cacheKey = "fx-widget-cache-v1";
const latestTtlMs = 60_000;
const historyTtlMs = 12 * 60 * 60 * 1000;

const popularCurrencies = [
  "EUR",
  "CNY",
  "USD",
  "HKD",
  "JPY",
  "GBP",
  "AUD",
  "CAD",
  "CHF",
  "SGD"
];

const state = {
  base: "EUR",
  quote: "CNY",
  years: 5,
  amount: 10000,
  lastData: null,
  refreshId: 0
};

const els = {
  pairLabel: document.querySelector("#pairLabel"),
  baseName: document.querySelector("#baseName"),
  quoteName: document.querySelector("#quoteName"),
  currentRate: document.querySelector("#currentRate"),
  providerStatus: document.querySelector("#providerStatus"),
  lastUpdated: document.querySelector("#lastUpdated"),
  baseCurrency: document.querySelector("#baseCurrency"),
  quoteCurrency: document.querySelector("#quoteCurrency"),
  yearsInput: document.querySelector("#yearsInput"),
  amountInput: document.querySelector("#amountInput"),
  lowRate: document.querySelector("#lowRate"),
  lowDate: document.querySelector("#lowDate"),
  highRate: document.querySelector("#highRate"),
  highDate: document.querySelector("#highDate"),
  amountLabel: document.querySelector("#amountLabel"),
  baseReceived: document.querySelector("#baseReceived"),
  lossCny: document.querySelector("#lossCny"),
  savingCny: document.querySelector("#savingCny"),
  lossHint: document.querySelector("#lossHint"),
  savingHint: document.querySelector("#savingHint"),
  chart: document.querySelector("#chart"),
  refreshButton: document.querySelector("#refreshButton"),
  swapButton: document.querySelector("#swapButton"),
  minButton: document.querySelector("#minButton"),
  closeButton: document.querySelector("#closeButton")
};

const providers = {
  frankfurter: {
    name: "Frankfurter",
    async latest(base, quote) {
      const data = await fetchJson(`${apiBase}/latest?from=${base}&to=${quote}`);
      return {
        base: data.base,
        quote,
        rate: Number(data.rates[quote]),
        date: data.date
      };
    },
    async history(base, quote, years) {
      const today = new Date();
      const from = new Date(today);
      from.setFullYear(today.getFullYear() - years);
      const range = `${toIsoDate(from)}..${toIsoDate(today)}`;
      const data = await fetchJson(`${apiBase}/${range}?from=${base}&to=${quote}`);
      return normalizeHistory(data.rates, quote);
    },
    async currencies() {
      const rows = await fetchJson(`${apiBase}/currencies`);
      return Object.keys(rows).sort();
    }
  }
};

function readJson(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key)) || fallback;
  } catch {
    return fallback;
  }
}

function writeJson(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function cacheGet(key, ttlMs) {
  const cache = readJson(cacheKey, {});
  const item = cache[key];
  if (!item || Date.now() - item.savedAt > ttlMs) return null;
  return item.value;
}

function cacheSet(key, value) {
  const cache = readJson(cacheKey, {});
  cache[key] = { savedAt: Date.now(), value };
  writeJson(cacheKey, cache);
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

function formatRate(value) {
  return new Intl.NumberFormat("zh-CN", {
    minimumFractionDigits: 4,
    maximumFractionDigits: 6
  }).format(value);
}

function formatMoney(value, currency) {
  return new Intl.NumberFormat("zh-CN", {
    style: "currency",
    currency,
    currencyDisplay: "code",
    maximumFractionDigits: 2
  }).format(value);
}

function formatNumber(value) {
  return new Intl.NumberFormat("zh-CN", {
    maximumFractionDigits: 4
  }).format(value);
}

function fillSelect(select, currencies, selected) {
  select.replaceChildren(
    ...currencies.map((currency) => {
      const option = document.createElement("option");
      option.value = currency;
      option.textContent = currency;
      option.selected = currency === selected;
      return option;
    })
  );
}

function saveSettings() {
  writeJson(settingsKey, {
    base: state.base,
    quote: state.quote,
    years: state.years,
    amount: state.amount
  });
}

function loadSettings() {
  const saved = readJson(settingsKey, {});
  state.base = saved.base || state.base;
  state.quote = saved.quote || state.quote;
  state.years = clampNumber(saved.years, 1, 30, state.years);
  state.amount = clampNumber(saved.amount, 1, 1_000_000_000, state.amount);
  els.yearsInput.value = state.years;
  els.amountInput.value = state.amount;
}

function setStatus(text, tone = "normal") {
  els.providerStatus.textContent = text;
  els.providerStatus.dataset.tone = tone;
}

function setLoading(isLoading) {
  els.refreshButton.disabled = isLoading;
  els.refreshButton.classList.toggle("is-loading", isLoading);
}

async function getCurrencies() {
  const cached = cacheGet("currencies", historyTtlMs);
  if (cached) return cached;

  try {
    const currencies = await providers.frankfurter.currencies();
    cacheSet("currencies", currencies);
    return currencies;
  } catch {
    return popularCurrencies;
  }
}

async function initCurrencies() {
  const currencies = Array.from(new Set([...popularCurrencies, state.base, state.quote, ...(await getCurrencies())])).sort();
  fillSelect(els.baseCurrency, currencies, state.base);
  fillSelect(els.quoteCurrency, currencies, state.quote);
}

async function loadPairData(provider, base, quote, years) {
  const latestKey = `latest:${base}:${quote}`;
  const historyKey = `history:${base}:${quote}:${years}:${toIsoDate(new Date())}`;
  const cachedLatest = cacheGet(latestKey, latestTtlMs);
  const cachedHistory = cacheGet(historyKey, historyTtlMs);

  if (cachedLatest && cachedHistory) {
    return { latest: cachedLatest, history: cachedHistory, stale: false };
  }

  try {
    const [latest, history] = await Promise.all([
      cachedLatest ? Promise.resolve(cachedLatest) : provider.latest(base, quote),
      cachedHistory ? Promise.resolve(cachedHistory) : provider.history(base, quote, years)
    ]);

    cacheSet(latestKey, latest);
    cacheSet(historyKey, history);
    return { latest, history, stale: false };
  } catch (error) {
    if (cachedLatest && cachedHistory) {
      return { latest: cachedLatest, history: cachedHistory, stale: true };
    }
    throw error;
  }
}

function renderChart(points, low, high) {
  if (!points.length) {
    els.chart.replaceChildren();
    return;
  }

  const width = 420;
  const height = 120;
  const pad = 10;
  const min = Math.min(...points.map((point) => point.rate));
  const max = Math.max(...points.map((point) => point.rate));
  const spread = max - min || 1;
  const step = (width - pad * 2) / Math.max(points.length - 1, 1);
  const path = points
    .map((point, index) => {
      const x = pad + index * step;
      const y = height - pad - ((point.rate - min) / spread) * (height - pad * 2);
      return `${index === 0 ? "M" : "L"} ${x.toFixed(2)} ${y.toFixed(2)}`;
    })
    .join(" ");

  const mark = (point, color) => {
    const index = points.findIndex((item) => item.date === point.date);
    const x = pad + index * step;
    const y = height - pad - ((point.rate - min) / spread) * (height - pad * 2);
    return `<circle cx="${x.toFixed(2)}" cy="${y.toFixed(2)}" r="4" fill="${color}" />`;
  };

  els.chart.innerHTML = `
    <line x1="${pad}" y1="${height - pad}" x2="${width - pad}" y2="${height - pad}" stroke="#d8e0ea" />
    <path d="${path}" fill="none" stroke="#0f766e" stroke-width="3" stroke-linecap="round" />
    ${mark(low, "#b42318")}
    ${mark(high, "#087443")}
  `;
}

function render(data) {
  const { latest, history, stale } = data;
  const { low, high } = minMax(history);
  if (!low || !high || !Number.isFinite(latest.rate)) return;

  const comparison = calculateComparison({
    amount: state.amount,
    currentRate: latest.rate,
    lowRate: low.rate,
    highRate: high.rate
  });

  els.pairLabel.textContent = `${state.base}/${state.quote}`;
  els.baseName.textContent = state.base;
  els.quoteName.textContent = state.quote;
  els.currentRate.textContent = formatRate(latest.rate);
  els.lastUpdated.textContent = `${latest.date} 更新${stale ? "，离线缓存" : ""}`;
  els.lowRate.textContent = formatRate(low.rate);
  els.lowDate.textContent = low.date;
  els.highRate.textContent = formatRate(high.rate);
  els.highDate.textContent = high.date;
  els.amountLabel.textContent = `用 ${formatMoney(state.amount, state.quote)} 兑换 ${state.base}`;
  els.baseReceived.textContent = `${formatNumber(comparison.receivedNow)} ${state.base}`;
  els.lossCny.textContent = formatMoney(comparison.lossInQuote, state.quote);
  els.savingCny.textContent = formatMoney(comparison.savingInQuote, state.quote);
  els.lossHint.textContent = `比 ${low.date} 低点少得，折算为 ${state.quote}`;
  els.savingHint.textContent = `比 ${high.date} 高点多得，折算为 ${state.quote}`;
  renderChart(history, low, high);
}

async function refresh() {
  saveSettings();

  if (state.base === state.quote) {
    setStatus("请选择不同币种", "warning");
    return;
  }

  const refreshId = ++state.refreshId;
  const provider = providers.frankfurter;
  setStatus("刷新中", "loading");
  setLoading(true);

  try {
    const data = await loadPairData(provider, state.base, state.quote, state.years);
    if (refreshId !== state.refreshId) return;
    state.lastData = data;
    render(data);
    setStatus(data.stale ? "离线缓存" : provider.name, data.stale ? "warning" : "normal");
  } catch (error) {
    if (refreshId !== state.refreshId) return;
    setStatus("刷新失败", "danger");
    els.lastUpdated.textContent = error.message;
  } finally {
    if (refreshId === state.refreshId) setLoading(false);
  }
}

function rerenderFromCache() {
  saveSettings();
  if (state.lastData) render(state.lastData);
}

function bindEvents() {
  els.baseCurrency.addEventListener("change", () => {
    state.base = els.baseCurrency.value;
    refresh();
  });

  els.quoteCurrency.addEventListener("change", () => {
    state.quote = els.quoteCurrency.value;
    refresh();
  });

  els.swapButton.addEventListener("click", () => {
    const nextBase = state.quote;
    state.quote = state.base;
    state.base = nextBase;
    els.baseCurrency.value = state.base;
    els.quoteCurrency.value = state.quote;
    refresh();
  });

  els.yearsInput.addEventListener("change", () => {
    state.years = clampNumber(els.yearsInput.value, 1, 30, 5);
    els.yearsInput.value = state.years;
    refresh();
  });

  els.amountInput.addEventListener("input", () => {
    state.amount = clampNumber(els.amountInput.value, 1, 1_000_000_000, 1);
    rerenderFromCache();
  });

  els.refreshButton.addEventListener("click", refresh);

  els.minButton.addEventListener("click", () => {
    window.fxWindow?.minimize();
  });

  els.closeButton.addEventListener("click", () => {
    window.fxWindow?.close();
  });
}

loadSettings();
await initCurrencies();
bindEvents();
await refresh();
window.setInterval(refresh, 60_000);
