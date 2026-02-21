import { useEffect, useState } from 'react';
import { fetchLeads, updateLead, fetchUserPosts } from '../lib/api';
import type { Lead } from '../types';
import { motion, AnimatePresence } from 'framer-motion';
import { Check, X, ChevronLeft, ChevronRight, ExternalLink } from 'lucide-react';
import { Card } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { makeImageUrl } from '../lib/image-proxy';

export default function ReviewQueue() {
    const [leads, setLeads] = useState<Lead[]>([]);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [loading, setLoading] = useState(true);
    const [direction, setDirection] = useState<'left' | 'right' | null>(null);

    // Current active lead's expanded data
    const [activeImages, setActiveImages] = useState<string[]>([]);
    const [imageIndex, setImageIndex] = useState(0);
    const [fetchingImages, setFetchingImages] = useState(false);

    useEffect(() => {
        loadLeads();
    }, []);

    async function loadLeads() {
        setLoading(true);
        try {
            const data = await fetchLeads('new', 50);
            setLeads(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    }

    const currentLead = leads[currentIndex];

    useEffect(() => {
        if (!currentLead) return;

        setImageIndex(0);
        // Parse existing images if available
        if (currentLead.post_images) {
            try {
                const parsed = JSON.parse(currentLead.post_images);
                if (Array.isArray(parsed) && parsed.length > 0) {
                    setActiveImages(parsed);
                    return;
                }
            } catch (e) {
                console.error("Failed to parse post_images", e);
            }
        }

        // If we reach here, post_images is empty or invalid. We must fetch.
        fetchAndSaveImages(currentLead);
    }, [currentLead]);

    async function fetchAndSaveImages(lead: Lead) {
        setFetchingImages(true);
        try {
            const posts = await fetchUserPosts(lead.username, 5);
            const urls = posts.map(p => p.image_url).filter(Boolean) as string[];

            // Fallback to best_post_image if everything else fails
            if (urls.length === 0 && lead.best_post_image) {
                urls.push(lead.best_post_image);
            }

            setActiveImages(urls);

            // Save back to DB
            await updateLead(lead.Id, { post_images: JSON.stringify(urls) });

            // Update local state to prevent re-fetching if we somehow come back to it
            setLeads(prev => {
                const next = [...prev];
                next[currentIndex] = { ...lead, post_images: JSON.stringify(urls) };
                return next;
            });

        } catch (e) {
            console.error("Failed to fetch images for lead", e);
            if (lead.best_post_image) setActiveImages([lead.best_post_image]);
        } finally {
            setFetchingImages(false);
        }
    }

    const handleAction = async (action: 'approved' | 'rejected') => {
        if (!currentLead) return;
        setDirection(action === 'approved' ? 'right' : 'left');

        try {
            // Optimistically move to next
            const leadId = currentLead.Id;
            setTimeout(() => {
                setCurrentIndex(prev => prev + 1);
                setDirection(null);
            }, 300); // match animation duration

            await updateLead(leadId, { status: action });
        } catch (e) {
            console.error("Failed to update status", e);
            // Revert in real app, but for now just log
        }
    };

    const nextImage = () => {
        if (imageIndex < activeImages.length - 1) setImageIndex(i => i + 1);
    };

    const prevImage = () => {
        if (imageIndex > 0) setImageIndex(i => i - 1);
    };

    if (loading) return <div className="p-8 flex justify-center">Loading queue...</div>;

    if (!currentLead) return (
        <div className="p-8 flex flex-col items-center justify-center space-y-4 h-[80vh]">
            <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                <Check size={32} />
            </div>
            <h2 className="text-2xl font-bold">Queue Empty!</h2>
            <p className="text-muted-foreground">You've reviewed all new leads.</p>
            <Button onClick={loadLeads}>Refresh</Button>
        </div>
    );

    return (
        <div className="flex flex-col items-center p-4 md:p-8 w-full max-w-lg mx-auto relative h-[calc(100vh-64px)] md:h-screen">
            <div className="w-full flex justify-between items-center mb-6">
                <h2 className="font-bold text-lg">Review Queue</h2>
                <Badge variant="secondary">{leads.length - currentIndex} left</Badge>
            </div>

            <div className="relative w-full aspect-[4/5] sm:aspect-auto sm:h-[600px] mb-8">
                <AnimatePresence mode="popLayout">
                    <motion.div
                        key={currentLead.Id}
                        initial={{ scale: 0.95, opacity: 0, x: 0 }}
                        animate={{ scale: 1, opacity: 1, x: 0 }}
                        exit={{
                            x: direction === 'right' ? 300 : direction === 'left' ? -300 : 0,
                            opacity: 0,
                            rotate: direction === 'right' ? 15 : direction === 'left' ? -15 : 0
                        }}
                        transition={{ duration: 0.3 }}
                        className="absolute inset-0 w-full h-full"
                        drag
                        dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
                        dragElastic={0.6}
                        onDragEnd={(_, { offset }) => {
                            const swipe = offset.x;
                            if (swipe > 100) handleAction('approved');
                            else if (swipe < -100) handleAction('rejected');
                        }}
                    >
                        <Card className="w-full h-full overflow-hidden shadow-xl flex flex-col border-0 md:border rounded-3xl relative">
                            <div className="relative flex-1 bg-black overflow-hidden group">
                                {activeImages.length > 0 ? (
                                    <>
                                        {/* Fallback Graphic (rendered behind the image) */}
                                        <div className="absolute inset-0 flex flex-col items-center justify-center bg-zinc-900 text-zinc-500 z-0">
                                            <span className="text-4xl mb-2 opacity-50">📸</span>
                                            <p className="font-medium text-sm">Image Protected by Instagram</p>
                                        </div>
                                        {/* Actual Image */}
                                        <img
                                            key={activeImages[imageIndex]} // Force remount on slide change to reset error states reliably
                                            src={makeImageUrl(activeImages[imageIndex])}
                                            alt={`Content ${imageIndex}`}
                                            className="absolute inset-0 w-full h-full object-cover transition-opacity duration-300 z-10"
                                            referrerPolicy="no-referrer"
                                            onError={(e) => {
                                                console.warn("Instagram blocked image load:", activeImages[imageIndex]);
                                                (e.target as HTMLImageElement).style.opacity = '0';
                                            }}
                                            onLoad={(e) => {
                                                (e.target as HTMLImageElement).style.opacity = '1';
                                            }}
                                        />
                                    </>
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center bg-muted text-muted-foreground text-sm">
                                        {fetchingImages ? "Loading images..." : "No images available"}
                                    </div>
                                )}

                                {/* Mobile tap zones */}
                                {activeImages.length > 1 && (
                                    <>
                                        <div className="absolute top-0 left-0 w-[40%] h-[70%] z-10" onClick={(e) => { e.stopPropagation(); prevImage(); }} />
                                        <div className="absolute top-0 right-0 w-[40%] h-[70%] z-10" onClick={(e) => { e.stopPropagation(); nextImage(); }} />
                                    </>
                                )}

                                {/* Carousel Controls */}
                                {activeImages.length > 1 && (
                                    <>
                                        <button
                                            onClick={(e) => { e.stopPropagation(); prevImage(); }}
                                            className="absolute left-2 top-1/2 -translate-y-1/2 p-1 rounded-full bg-black/30 text-white hover:bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity"
                                        >
                                            <ChevronLeft />
                                        </button>
                                        <button
                                            onClick={(e) => { e.stopPropagation(); nextImage(); }}
                                            className="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded-full bg-black/30 text-white hover:bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity"
                                        >
                                            <ChevronRight />
                                        </button>
                                        {/* Dots */}
                                        <div className="absolute top-4 left-0 w-full flex justify-center gap-1 z-10 px-4">
                                            {activeImages.map((_, i) => (
                                                <div
                                                    key={i}
                                                    className={`flex-1 h-1 rounded-full transition-all ${i === imageIndex ? 'bg-white' : 'bg-white/40'}`}
                                                />
                                            ))}
                                        </div>
                                    </>
                                )}

                                {/* Info Overlay (Tinder Style bottom gradient) */}
                                <div className="absolute bottom-0 w-full bg-gradient-to-t from-black/90 via-black/60 to-transparent p-6 text-white pt-24">
                                    <div className="flex justify-between items-end mb-2">
                                        <div>
                                            <a
                                                href={currentLead.profile_url || `https://instagram.com/${currentLead.username}`}
                                                target="_blank"
                                                rel="noreferrer"
                                                className="text-2xl font-bold flex items-center gap-2 hover:underline"
                                                onClick={(e) => e.stopPropagation()}
                                            >
                                                @{currentLead.username}
                                                <ExternalLink size={18} className="text-white/70" />
                                            </a>
                                            <p className="text-white/80 flex items-center gap-2 text-sm mt-1">
                                                👥 {currentLead.followers?.toLocaleString() || 0} followers
                                                <span className="text-white/40">•</span>
                                                📊 {currentLead.engagement_rate || 0}% eng.
                                            </p>
                                        </div>
                                        {currentLead.photo_score && (
                                            <div className="bg-primary/90 text-primary-foreground px-3 py-1 rounded-full text-sm font-bold shadow-lg">
                                                AI: {currentLead.photo_score}/40
                                            </div>
                                        )}
                                    </div>

                                    {currentLead.location_name && (
                                        <p className="text-sm font-medium text-white/90 mb-2">
                                            📍 {currentLead.location_name}
                                        </p>
                                    )}

                                    <p className="text-sm text-white/70 line-clamp-2">
                                        {currentLead.bio || "No bio"}
                                    </p>
                                </div>
                            </div>
                        </Card>
                    </motion.div>
                </AnimatePresence>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-6 justify-center w-full mt-auto mb-8">
                <button
                    onClick={() => handleAction('rejected')}
                    className="w-16 h-16 rounded-full bg-white border shadow-lg flex items-center justify-center text-red-500 hover:bg-red-50 hover:scale-110 transition-all active:scale-95"
                    disabled={!!direction}
                >
                    <X size={32} strokeWidth={3} />
                </button>
                <button
                    onClick={() => handleAction('approved')}
                    className="w-16 h-16 rounded-full bg-white border shadow-lg flex items-center justify-center text-green-500 hover:bg-green-50 hover:scale-110 transition-all active:scale-95"
                    disabled={!!direction}
                >
                    <Check size={32} strokeWidth={3} />
                </button>
            </div>
        </div>
    );
}
