import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'https://nocodb.restaurantreykjavik.com',
        changeOrigin: true,
        secure: false,
      },
      '/proxy-image': {
        target: 'https://scontent-atl3-3.cdninstagram.com',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/proxy-image/, ''),
        configure: (proxy, _options) => {
          proxy.on('error', (err, _req, _res) => {
            console.log('proxy error', err);
          });
          proxy.on('proxyReq', (proxyReq, req, _res) => {
            const urlObj = new URL(req.url, 'http://localhost');
            const targetUrlStr = urlObj.searchParams.get('url');

            if (targetUrlStr) {
              const targetUrl = new URL(targetUrlStr);
              proxyReq.host = targetUrl.host;
              proxyReq.protocol = targetUrl.protocol;
              proxyReq.path = targetUrl.pathname + targetUrl.search;
              proxyReq.setHeader('Host', targetUrl.host);
            }

            proxyReq.setHeader('referer', 'https://www.instagram.com/');
            proxyReq.setHeader('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36');
            proxyReq.removeHeader('origin');
          });
          proxy.on('proxyRes', (proxyRes, req, _res) => {
            proxyRes.headers['access-control-allow-origin'] = '*';
            proxyRes.headers['access-control-allow-methods'] = 'GET, OPTIONS';
            proxyRes.headers['access-control-allow-headers'] = 'Origin, X-Requested-With, Content-Type, Accept';
            proxyRes.headers['cross-origin-resource-policy'] = 'cross-origin'; // Overwrite their broken CORP header
          });
        }
      }
    }
  }
})
