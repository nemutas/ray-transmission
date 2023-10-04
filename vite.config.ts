import { defineConfig } from 'vite'
import glsl from 'vite-plugin-glsl'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig(() => {
  return {
    root: './src',
    publicDir: '../public',
    base: '/ray-transmission/',
    build: {
      outDir: '../dist',
    },
    plugins: [tsconfigPaths(), glsl()],
    server: {
      host: true,
    },
  }
})
