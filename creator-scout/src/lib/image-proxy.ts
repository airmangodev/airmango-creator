export function makeImageUrl(url: string | undefined | null): string | undefined {
    if (!url) return undefined;
    if (url.includes('instagram.com')) {
        return `/proxy-image?url=${encodeURIComponent(url)}`;
    }
    return url;
}
