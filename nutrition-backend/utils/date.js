const TIME_ZONE = 'Asia/Ho_Chi_Minh';

function todayVN() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

function isDateString(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function normalizeDate(value) {
  if (isDateString(value)) return value;
  return todayVN();
}

function addDays(dateString, days) {
  const [y, m, d] = normalizeDate(dateString).split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  date.setUTCDate(date.getUTCDate() + Number(days || 0));
  return date.toISOString().slice(0, 10);
}

function getLast7DaysRange(endDate) {
  const end = normalizeDate(endDate);
  return {
    start: addDays(end, -6),
    end,
  };
}

function getMonthRange(monthInput) {
  const month = typeof monthInput === 'string' && /^\d{4}-\d{2}$/.test(monthInput)
    ? monthInput
    : todayVN().slice(0, 7);

  const [y, m] = month.split('-').map(Number);
  const start = `${month}-01`;
  const endDate = new Date(Date.UTC(y, m, 0));
  const end = endDate.toISOString().slice(0, 10);

  return { month, start, end };
}

function enumerateDates(start, end) {
  const dates = [];
  let current = normalizeDate(start);
  const last = normalizeDate(end);

  while (current <= last) {
    dates.push(current);
    current = addDays(current, 1);
    if (dates.length > 370) break;
  }

  return dates;
}

module.exports = {
  todayVN,
  normalizeDate,
  addDays,
  getLast7DaysRange,
  getMonthRange,
  enumerateDates,
};
