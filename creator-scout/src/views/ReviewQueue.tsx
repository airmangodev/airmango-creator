import { useEffect, useState, useCallback } from 'react';
import { fetchOutreachLeads, approveAndSendEmail, rejectOutreachLead, getOutreachCounts } from '../lib/api';
import type { OutreachLead } from '../types';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, ExternalLink, Loader2, Mail, MapPin, Send, SkipForward, X } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { makeImageUrl } from '../lib/image-proxy';
import { formatNumber } from '../lib/utils';
import { showToast } from '../components/ui/Toast';

export default function ReviewQueue() {
    const [leads, setLeads] = useState<OutreachLead[]>([]);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [loading, setLoading] = useState(true);
    const [actionInProgress, setActionInProgress] = useState(false);

    // Image carousel state
    const [activeImages, setActiveImages] = useState<string[]>([]);
    const [imageIndex, setImageIndex] = useState(0);
    const [imgStatus, setImgStatus] = useState<'loading' | 'loaded' | 'error'>('loading');

    // Email editor state
    const [editedSubject, setEditedSubject] = useState('');
    const [editedBody, setEditedBody] = useState('');

    // Bio expand
    const [bioExpanded, setBioExpanded] = useState(false);

    // Counts
    const [pendingCount, setPendingCount] = useState(0);
    const [sentTodayCount, setSentTodayCount] = useState(0);

    useEffect(() => {
        loadLeads();
        loadCounts();
    }, []);

    async function loadLeads() {
        setLoading(true);
        try {
            const data = await fetchOutreachLeads('pending_approval', 200);
            setLeads(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    }

    async function loadCounts() {
        try {
            const counts = await getOutreachCounts();
            setPendingCount(counts.pending);
            // Count sent today
            const allSent = await fetchOutreachLeads('sent', 500);
            const today = new Date().toISOString().split('T')[0];
            const sentToday = allSent.filter(l => l.sent_at && l.sent_at.startsWith(today)).length;
            setSentTodayCount(sentToday);
        } catch (e) {
            console.error(e);
        }
    }

    const currentLead = leads[currentIndex];

    // Update images and email editor when lead changes
    useEffect(() => {
        if (!currentLead) return;

        setImageIndex(0);
        setBioExpanded(false);
        setEditedSubject(currentLead.email_subject || '');
        setEditedBody(currentLead.email_body || '');

        // Parse post_images
        const images: string[] = [];
        if (currentLead.best_post_image) images.push(currentLead.best_post_image);
        if (currentLead.post_images) {
            try {
                const parsed = JSON.parse(currentLead.post_images);
                if (Array.isArray(parsed)) {
                    parsed.forEach((url: string) => {
                        if (url && !images.includes(url)) images.push(url);
                    });
                }
            } catch (e) {
                console.error("Failed to parse post_images", e);
            }
        }
        setActiveImages(images.length > 0 ? images : []);
    }, [currentLead]);

    useEffect(() => {
        setImgStatus('loading');
    }, [imageIndex, activeImages]);

    const nextImage = () => {
        if (imageIndex < activeImages.length - 1) setImageIndex(i => i + 1);
    };
    const prevImage = () => {
        if (imageIndex > 0) setImageIndex(i => i - 1);
    };

    const goNext = useCallback(() => {
        if (currentIndex < leads.length - 1) {
            setCurrentIndex(prev => prev + 1);
        }
    }, [currentIndex, leads.length]);

    const handleApprove = useCallback(async () => {
        if (!currentLead || actionInProgress) return;
        setActionInProgress(true);

        try {
            await approveAndSendEmail(currentLead, editedSubject, editedBody);
            showToast(`Email approved — sending to ${currentLead.email}`, 'success');
            setPendingCount(prev => Math.max(0, prev - 1));
            setSentTodayCount(prev => prev + 1);
        } catch (e) {
            console.error(e);
            showToast('Failed to send email', 'error');
        }

        setTimeout(() => {
            setCurrentIndex(prev => prev + 1);
            setActionInProgress(false);
        }, 300);
    }, [currentLead, editedSubject, editedBody, actionInProgress]);

    const handleReject = useCallback(async () => {
        if (!currentLead || actionInProgress) return;
        setActionInProgress(true);

        try {
            await rejectOutreachLead(currentLead.Id);
            showToast(`Rejected @${currentLead.username}`, 'info');
            setPendingCount(prev => Math.max(0, prev - 1));
        } catch (e) {
            console.error(e);
            showToast('Failed to reject lead', 'error');
        }

        setTimeout(() => {
            setCurrentIndex(prev => prev + 1);
            setActionInProgress(false);
        }, 300);
    }, [currentLead, actionInProgress]);

    // Keyboard shortcuts
    useEffect(() => {
        function handleKeyDown(e: KeyboardEvent) {
            const target = e.target as HTMLElement;
            if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;
            if (!currentLead) return;

            if (e.key === 'Enter') {
                e.preventDefault();
                handleApprove();
            } else if (e.key.toLowerCase() === 'r') {
                e.preventDefault();
                handleReject();
            } else if (e.key.toLowerCase() === 's') {
                e.preventDefault();
                goNext();
            }
        }
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [currentLead, handleApprove, handleReject, goNext]);

    if (loading) {
        return (
            <div className="p-8 flex items-center justify-center h-[80vh]">
                <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
            </div>
        );
    }

    if (!currentLead) {
        return (
            <div className="p-8 flex flex-col items-center justify-center space-y-4 h-[80vh]">
                <div className="w-20 h-20 rounded-full bg-emerald-50 flex items-center justify-center">
                    <Mail className="w-10 h-10 text-emerald-500" />
                </div>
                <h2 className="text-2xl font-bold">Queue is clear</h2>
                <p className="text-muted-foreground">No pending emails to review.</p>
                <Button onClick={() => { setCurrentIndex(0); loadLeads(); }}>Refresh</Button>
            </div>
        );
    }

    return (
        <div className="flex flex-col h-full">
            {/* Header */}
            <div className="flex items-center justify-between px-8 py-4 border-b bg-card">
                <h2 className="text-xl font-bold">Review Queue</h2>
                <div className="flex gap-2">
                    <Badge className="bg-amber-100 text-amber-800 hover:bg-amber-100">{pendingCount} pending</Badge>
                    <Badge className="bg-blue-100 text-blue-800 hover:bg-blue-100">{sentTodayCount} sent today</Badge>
                </div>
            </div>

            {/* Two-column layout */}
            <div className="flex-1 flex overflow-hidden">
                <AnimatePresence mode="popLayout">
                    <motion.div
                        key={currentLead.Id}
                        initial={{ opacity: 0, x: 60 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ x: -400, opacity: 0 }}
                        transition={{ duration: 0.3 }}
                        className="flex-1 flex overflow-hidden"
                    >
                        {/* LEFT COLUMN: Creator Profile */}
                        <div className="w-1/2 border-r overflow-y-auto p-6 space-y-5">
                            {/* Image Carousel */}
                            <div className="relative aspect-[4/5] rounded-xl overflow-hidden bg-black group">
                                {activeImages.length > 0 ? (
                                    <>
                                        {imgStatus === 'loading' && (
                                            <div className="absolute inset-0 flex flex-col items-center justify-center bg-zinc-900 text-zinc-500 z-0">
                                                <Loader2 className="w-8 h-8 animate-spin mb-2 text-white/50" />
                                            </div>
                                        )}
                                        {imgStatus === 'error' && (
                                            <div className="absolute inset-0 flex flex-col items-center justify-center bg-zinc-900 text-zinc-500 z-0">
                                                <span className="text-4xl mb-2 opacity-50">📸</span>
                                                <p className="font-medium text-sm">Image unavailable</p>
                                            </div>
                                        )}
                                        <img
                                            key={activeImages[imageIndex]}
                                            src={makeImageUrl(activeImages[imageIndex])}
                                            alt={`Post ${imageIndex + 1}`}
                                            className="absolute inset-0 w-full h-full object-cover transition-opacity duration-300 z-10"
                                            referrerPolicy="no-referrer"
                                            onError={(e) => {
                                                (e.target as HTMLImageElement).style.opacity = '0';
                                                setImgStatus('error');
                                            }}
                                            onLoad={(e) => {
                                                (e.target as HTMLImageElement).style.opacity = '1';
                                                setImgStatus('loaded');
                                            }}
                                            style={{ opacity: imgStatus === 'loaded' ? 1 : 0 }}
                                        />
                                    </>
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center bg-muted text-muted-foreground text-sm">
                                        No images available
                                    </div>
                                )}

                                {/* Carousel controls */}
                                {activeImages.length > 1 && (
                                    <>
                                        <button
                                            onClick={prevImage}
                                            className="absolute left-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/30 text-white hover:bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity z-20"
                                        >
                                            <ChevronLeft size={20} />
                                        </button>
                                        <button
                                            onClick={nextImage}
                                            className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/30 text-white hover:bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity z-20"
                                        >
                                            <ChevronRight size={20} />
                                        </button>
                                        <div className="absolute top-3 left-0 w-full flex justify-center gap-1 z-20 px-4">
                                            {activeImages.map((_, i) => (
                                                <div
                                                    key={i}
                                                    className={`flex-1 h-1 rounded-full transition-all ${i === imageIndex ? 'bg-white' : 'bg-white/40'}`}
                                                />
                                            ))}
                                        </div>
                                    </>
                                )}

                                {/* Photo score overlay */}
                                {currentLead.photo_score != null && (
                                    <div className="absolute bottom-3 right-3 bg-black/70 text-white px-2.5 py-1 rounded-full text-xs font-bold z-20">
                                        ⭐ {currentLead.photo_score}/10
                                    </div>
                                )}
                            </div>

                            {/* Profile Row */}
                            <div className="flex items-center gap-3">
                                <div className="w-12 h-12 rounded-full overflow-hidden bg-muted flex-shrink-0">
                                    {currentLead.profile_pic ? (
                                        <img
                                            src={makeImageUrl(currentLead.profile_pic)}
                                            className="w-full h-full object-cover"
                                            referrerPolicy="no-referrer"
                                            onError={(e) => {
                                                (e.target as HTMLImageElement).style.display = 'none';
                                            }}
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-lg font-bold text-muted-foreground uppercase">
                                            {currentLead.username.charAt(0)}
                                        </div>
                                    )}
                                </div>
                                <div className="min-w-0 flex-1">
                                    <a
                                        href={currentLead.profile_url || `https://instagram.com/${currentLead.username}`}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="font-semibold text-base flex items-center gap-1.5 hover:underline"
                                    >
                                        @{currentLead.username}
                                        <ExternalLink size={14} className="text-muted-foreground" />
                                    </a>
                                    {currentLead.location_name && (
                                        <p className="text-sm text-muted-foreground flex items-center gap-1">
                                            <MapPin size={13} />
                                            {currentLead.location_name}
                                        </p>
                                    )}
                                </div>
                            </div>

                            {/* Stats Grid */}
                            <div className="grid grid-cols-3 gap-3">
                                <div className="bg-muted/50 rounded-lg p-3 text-center">
                                    <div className="text-lg font-bold">{formatNumber(currentLead.followers)}</div>
                                    <div className="text-xs text-muted-foreground">Followers</div>
                                </div>
                                <div className="bg-muted/50 rounded-lg p-3 text-center">
                                    <div className="text-lg font-bold">{currentLead.engagement_rate || 0}%</div>
                                    <div className="text-xs text-muted-foreground">Engagement</div>
                                </div>
                                <div className="bg-muted/50 rounded-lg p-3 text-center">
                                    <div className="text-lg font-bold">{formatNumber(currentLead.avg_likes)}</div>
                                    <div className="text-xs text-muted-foreground">Avg Likes</div>
                                </div>
                            </div>

                            {/* Bio */}
                            {currentLead.bio && (
                                <div>
                                    <p className={`text-sm text-muted-foreground ${!bioExpanded ? 'line-clamp-3' : ''}`}>
                                        {currentLead.bio}
                                    </p>
                                    {currentLead.bio.length > 150 && (
                                        <button
                                            onClick={() => setBioExpanded(!bioExpanded)}
                                            className="text-xs text-primary font-medium mt-1 hover:underline"
                                        >
                                            {bioExpanded ? 'Show less' : 'Show more'}
                                        </button>
                                    )}
                                </div>
                            )}

                            {/* Email Badge */}
                            <div className="flex items-center gap-2 px-3 py-2.5 rounded-lg" style={{ backgroundColor: '#FFF0F4' }}>
                                <Mail size={16} style={{ color: '#D91C60' }} />
                                <span className="text-sm font-medium" style={{ color: '#D91C60' }}>{currentLead.email}</span>
                            </div>
                        </div>

                        {/* RIGHT COLUMN: Email Editor */}
                        <div className="w-1/2 flex flex-col overflow-hidden">
                            <div className="p-6 flex-1 overflow-y-auto space-y-4">
                                {/* Header */}
                                <div className="flex items-center justify-between">
                                    <h3 className="text-lg font-bold">Email Preview</h3>
                                    <Button variant="outline" size="sm" disabled className="opacity-50 text-xs">
                                        Regenerate
                                    </Button>
                                </div>

                                {/* To field (readonly) */}
                                <div>
                                    <label className="text-xs font-medium text-muted-foreground mb-1 block">To</label>
                                    <div className="w-full px-3 py-2 rounded-md border bg-muted/50 text-sm text-muted-foreground">
                                        {currentLead.email}
                                    </div>
                                </div>

                                {/* Subject field (editable) */}
                                <div>
                                    <label className="text-xs font-medium text-muted-foreground mb-1 block">Subject</label>
                                    <input
                                        type="text"
                                        value={editedSubject}
                                        onChange={(e) => setEditedSubject(e.target.value)}
                                        className="w-full px-3 py-2 rounded-md border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                                    />
                                </div>

                                {/* Body field (editable) */}
                                <div className="flex-1">
                                    <label className="text-xs font-medium text-muted-foreground mb-1 block">Body</label>
                                    <textarea
                                        value={editedBody}
                                        onChange={(e) => setEditedBody(e.target.value)}
                                        className="w-full px-3 py-2 rounded-md border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary resize-y font-mono leading-relaxed"
                                        style={{ minHeight: '280px' }}
                                    />
                                </div>
                            </div>

                            {/* Action Bar */}
                            <div className="border-t px-6 py-4 flex items-center justify-between bg-card">
                                <div className="flex gap-2">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={goNext}
                                        disabled={actionInProgress || currentIndex >= leads.length - 1}
                                        className="gap-1.5"
                                    >
                                        <SkipForward size={14} />
                                        Skip
                                        <kbd className="ml-1 text-[10px] bg-muted px-1 py-0.5 rounded font-mono">S</kbd>
                                    </Button>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={handleReject}
                                        disabled={actionInProgress}
                                        className="gap-1.5 text-red-600 border-red-200 hover:bg-red-50 hover:text-red-700"
                                    >
                                        <X size={14} />
                                        Reject
                                        <kbd className="ml-1 text-[10px] bg-muted px-1 py-0.5 rounded font-mono">R</kbd>
                                    </Button>
                                </div>
                                <Button
                                    size="sm"
                                    onClick={handleApprove}
                                    disabled={actionInProgress}
                                    className="gap-1.5 text-white"
                                    style={{ backgroundColor: '#D91C60' }}
                                    onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#C01854')}
                                    onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#D91C60')}
                                >
                                    <Send size={14} />
                                    Approve & Send
                                    <kbd className="ml-1 text-[10px] bg-white/20 px-1 py-0.5 rounded font-mono">↵</kbd>
                                </Button>
                            </div>
                        </div>
                    </motion.div>
                </AnimatePresence>
            </div>
        </div>
    );
}
