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

function App() {
  const [shows, setShows] = React.useState([]);
  const [query, setQuery] = React.useState('');
  const [sortField, setSortField] = React.useState('');
  const [asc, setAsc] = React.useState(true);

  React.useEffect(() => {
    fetch('shows.csv')
      .then(res => res.text())
      .then(text => setShows(parseCSV(text)))
      .catch(() => setShows([]));
  }, []);

  const filtered = shows.filter(show => {
    const q = query.toLowerCase();
    return (
      show['Location'].toLowerCase().includes(q) ||
      show['Artist'].toLowerCase().includes(q) ||
      show['Venue'].toLowerCase().includes(q)
    );
  });

  const sorted = React.useMemo(() => {
    if (!sortField) return filtered;
    return [...filtered].sort((a, b) => {
      const av = a[sortField] || '';
      const bv = b[sortField] || '';
      return asc ? av.localeCompare(bv) : bv.localeCompare(av);
    });
  }, [filtered, sortField, asc]);

  return (
    <div className="container">
      <h1>Spencer Tweedy Shows</h1>
      <p><a href="index.html">Back to datasets</a></p>
      <input
        className="search"
        placeholder="Search..."
        value={query}
        onChange={e => setQuery(e.target.value)}
      />
      <table className="table">
        <thead>
          <tr>
            {['Date', 'Location', 'Artist', 'Venue'].map(field => (
              <th
                key={field}
                onClick={() => {
                  setSortField(field);
                  setAsc(field === sortField ? !asc : true);
                }}
              >
                {field}
                {sortField === field ? (asc ? ' ▲' : ' ▼') : ''}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sorted.map((show, i) => (
            <tr key={i}>
              <td>{show['Date']}</td>
              <td>{show['Location']}</td>
              <td>{show['Artist']}</td>
              <td>{show['Venue']}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
