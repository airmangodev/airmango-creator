import { defineConfig, type ProxyOptions } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/

const proxyConfig: Record<string, string | ProxyOptions> = {
  '/api': {
    target: 'https://nocodb.restaurantreykjavik.com',
    changeOrigin: true,
    secure: false,
  },
  '/proxy-image': {
    target: 'https://scontent-atl3-3.cdninstagram.com',
    changeOrigin: true,
    secure: false,
    rewrite: (path: string) => path.replace(/^\/proxy-image/, ''),
    configure: (proxy: any, _options: any) => {
      proxy.on('error', (err: any, _req: any, _res: any) => {
        console.log('proxy error', err);
      });
      proxy.on('proxyReq', (proxyReq: any, req: any, _res: any) => {
        const urlObj = new URL(req.url || '/', 'http://localhost');
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
      proxy.on('proxyRes', (proxyRes: any, _req: any, _res: any) => {
        proxyRes.headers['access-control-allow-origin'] = '*';
        proxyRes.headers['access-control-allow-methods'] = 'GET, OPTIONS';
        proxyRes.headers['access-control-allow-headers'] = 'Origin, X-Requested-With, Content-Type, Accept';
        proxyRes.headers['cross-origin-resource-policy'] = 'cross-origin'; // Overwrite their broken CORP header
      });
    }
  }
};

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    proxy: proxyConfig
  },
  preview: {
    proxy: proxyConfig
  }
})
