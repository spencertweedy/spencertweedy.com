module.exports = {
  content: [
    './_includes/**/*.html',
    './_layouts/**/*.html',
    './content/**/*.{html,md}',
    './pages/**/*.{html,md}', // one level deep
  ],
  theme: {
    fontFamily: {
      sans: ['jaf-facitweb', 'sans-serif'],
      ft88: ['"FT88 Italic"'],
    },
    extend: {
      colors: {
        'obs-green': 'hsl(87, 47%, 52%)',
      },
      fontSize: {
        biggie: 'calc(1.4em + 1.6vw)',
      },
      animation: {
        'enter': 'enter 0.4s',
      },
      keyframes: {
        enter: {
          '0%': { transform: 'scale(0.2)' },
          '100%': { transform: 'scale(1)' },
        }
      }
    }
  }
}