import type { Config } from 'tailwindcss'

export default {
  content: ['./app/**/*.{vue,ts}'],
  theme: {
    extend: {
      colors: {
        paper: '#FAF9F6',
        ink: {
          DEFAULT: '#2C2C2C',
          light: '#8A8A8A',
        },
      },
      fontFamily: {
        serif: ['Georgia', 'Cambria', '"Times New Roman"', 'Times', 'serif'],
        lora: ['Lora', 'Georgia', 'serif'],
        literata: ['Literata', 'Georgia', 'serif'],
        crimson: ['"Crimson Pro"', 'Georgia', 'serif'],
        garamond: ['"EB Garamond"', 'Georgia', 'serif'],
        typewriter: ['"Special Elite"', 'Courier', 'monospace'],
        ui: ['"Noto Sans"', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        editor: ['1.08rem', { lineHeight: '1.9', letterSpacing: '0.01em' }],
      },
      maxWidth: {
        prose: '650px',
      },
    },
  },
} satisfies Config
