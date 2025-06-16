const MiniReact = {
  createElement(type, props, ...children) {
    if (typeof type === 'function') {
      return type(Object.assign({}, props, { children }));
    }
    const el = document.createElement(type);
    for (const [key, value] of Object.entries(props || {})) {
      if (key === 'className') {
        el.className = value;
      } else if (key.startsWith('on') && typeof value === 'function') {
        el.addEventListener(key.substring(2).toLowerCase(), value);
      } else {
        el.setAttribute(key, value);
      }
    }
    children.flat().forEach(child => {
      if (child === null || child === undefined) return;
      if (typeof child === 'string' || typeof child === 'number') {
        el.appendChild(document.createTextNode(child));
      } else {
        el.appendChild(child);
      }
    });
    return el;
  },
  render(element, container) {
    container.innerHTML = '';
    container.appendChild(element);
  }
};

window.MiniReact = MiniReact;
