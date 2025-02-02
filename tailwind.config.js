module.exports = {
  content: [
    './_includes/**/*.html',
    './_layouts/**/*.html',
    './content/**/*.{html,md}',
    './pages/**/*.{html,md}', // one level deep
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['jaf-facitweb', 'sans-serif'],
        serif: ['"Times New Roman"', 'Times', 'Georgia', 'Cambria', 'serif'],
        mono: ['ISO','monospace'],
      },
      colors: {
        'obs-green': 'hsl(87, 47%, 52%)',
        'buchla-blue': '#3D7FF2',
        'buchla-orange': '#FF542E',
        'buchla-yellow': '#FFD84D',
        'buchla-green': '#39A362',
        'buchla-red': '#E63B2C',
      },
      fontSize: {
        'biggie': 'calc(1.6em + 1.6vw)',
        'biggie-small': 'calc(1em + 1vw)',
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