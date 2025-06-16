function App() {
  return (
    <div className="container">
      <h1>Music Data Explorer</h1>
      <nav>
        <ul>
          <li><a href="spencer.html">Spencer Tweedy</a></li>
          <li><a href="#">David Berman (coming soon)</a></li>
        </ul>
      </nav>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
