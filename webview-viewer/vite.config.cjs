const {defineConfig} = require('vite');
const react = require('@vitejs/plugin-react');
const path = require('path');

// https://vitejs.dev/config/
export default defineConfig({
  mode: 'development',
  plugins: [react()],
  server: {
    port: 3000,
    host: "0.0.0.0"
  },
  build: {
    outDir: 'build',
    manifest: 'asset-manifest.json'
  }
})
