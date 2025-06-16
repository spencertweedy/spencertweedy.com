function App() {
  const datasets = [
    { name: 'Spencer Tweedy', href: 'spencer.html' },
    { name: 'David Berman (coming soon)', href: '#' }
  ];
  return (
    <div className="container">
      <h1>Music Data Explorer</h1>
      <div className="cards">
        {datasets.map(ds => (
          <a key={ds.name} href={ds.href} className="card">
            {ds.name}
          </a>
        ))}
      </div>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
