module.exports = {
  content: [
    './_includes/**/*.html',
    './_layouts/**/*.html',
    './_posts/*.md',
    './**/*.{html,md}',
  ],
  theme: {
    fontFamily: {
      sans: ['jaf-facitweb', 'sans-serif']
    },
    extend: {
      fontSize: {
        biggie: 'calc(1em + 2vw)'
      },
      animation: {
        'enter': 'enter 0.4s'
      },
      keyframes: {
        enter: {
          '0%': { transform: 'scale(0.2)' },
          '100%': { transform: 'scale(1)' }
        }
      }
    }
  }
}