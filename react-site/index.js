const h = MiniReact.createElement;

function App() {
  return h('div', {},
    h('h1', {}, 'Select Dataset'),
    h('nav', {},
      h('ul', {},
        h('li', {}, h('a', { href: 'spencer.html' }, 'Spencer Tweedy')),
        h('li', {}, h('a', { href: '#' }, 'David Berman (coming soon)'))
      )
    )
  );
}

document.addEventListener('DOMContentLoaded', () => {
  MiniReact.render(App(), document.getElementById('root'));
});
