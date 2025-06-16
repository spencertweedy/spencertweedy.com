const h = MiniReact.createElement;

function parseCSV(text) {
  const lines = text.trim().split(/\r?\n/);
  const headers = lines[0].split(',');
  return lines.slice(1).map(line => {
    const values = [];
    let i = 0, inQuotes = false, value = '';
    for (let char of line) {
      if (char === '"') {
        if (inQuotes && i + 1 < line.length && line[i+1] === '"') {
          value += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        values.push(value);
        value = '';
      } else {
        value += char;
      }
      i++;
    }
    values.push(value);
    const obj = {};
    headers.forEach((h, idx) => obj[h] = values[idx]);
    return obj;
  });
}

function ShowTable({ shows }) {
  return h('table', { className: 'table' },
    h('thead', {},
      h('tr', {},
        h('th', {}, 'Date'),
        h('th', {}, 'Location'),
        h('th', {}, 'Artist'),
        h('th', {}, 'Venue')
      )
    ),
    h('tbody', {},
      ...shows.map(show => h('tr', {},
        h('td', {}, show['Date']),
        h('td', {}, show['Location']),
        h('td', {}, show['Artist']),
        h('td', {}, show['Venue'])
      ))
    )
  );
}

function App({ shows }) {
  return h('div', {},
    h('h1', {}, 'Spencer Tweedy Shows'),
    h('p', {}, h('a', { href: 'index.html' }, 'Back to datasets')),
    ShowTable({ shows })
  );
}

fetch('shows.csv')
  .then(res => res.text())
  .then(text => {
    const shows = parseCSV(text);
    MiniReact.render(App({ shows }), document.getElementById('root'));
  })
  .catch(err => {
    document.getElementById('root').textContent = 'Failed to load data';
  });
