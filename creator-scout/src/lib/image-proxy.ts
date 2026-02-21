export function makeImageUrl(url: string | undefined | null): string | undefined {
    if (!url) return undefined;
    if (url.includes('instagram.com') || url.includes('fbcdn.net')) {
        return import.meta.env.DEV
            ? `/proxy-image?url=${encodeURIComponent(url)}` // Local Vite Proxy
            : `https://corsproxy.io/?url=${encodeURIComponent(url)}`; // Public CORS Proxy for static production
    }
    return url;
}
