import { useEffect, useState } from 'react';
import { fetchLeads, updateLead } from '../lib/api';
import type { Lead } from '../types';
import { Button } from '../components/ui/button';
import { ExternalLink, Check, Mail } from 'lucide-react';
import { makeImageUrl } from '../lib/image-proxy';

export default function ApprovedLeads() {
    const [leads, setLeads] = useState<Lead[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadLeads();
    }, []);

    async function loadLeads() {
        setLoading(true);
        try {
            const data = await fetchLeads('approved', 50);
            setLeads(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }

    const markContacted = async (id: number) => {
        try {
            await updateLead(id, { status: 'contacted' });
            setLeads(leads.filter(l => l.Id !== id));
        } catch (e) {
            console.error(e);
        }
    };

    if (loading) return <div className="p-8">Loading approved leads...</div>;

    return (
        <div className="p-8">
            <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold flex items-center gap-2">
                    <Check className="text-green-500" />
                    Approved Creators  ({leads.length})
                </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {leads.map(lead => (
                    <div key={lead.Id} className="border rounded-xl p-4 bg-card text-card-foreground shadow-sm flex flex-col">
                        <div className="flex items-start gap-4 mb-4">
                            <div className="w-16 h-16 rounded-full bg-muted overflow-hidden flex-shrink-0 flex items-center justify-center">
                                {lead.profile_pic ? (
                                    <img
                                        src={makeImageUrl(lead.profile_pic)}
                                        className="w-full h-full object-cover"
                                        referrerPolicy="no-referrer"
                                        onError={(e) => {
                                            (e.target as HTMLImageElement).style.display = 'none';
                                            const parent = (e.target as HTMLImageElement).parentElement;
                                            if (parent) {
                                                parent.classList.add('bg-primary/10');
                                                parent.innerHTML = `<span class="text-2xl font-bold uppercase text-primary">${lead.username.charAt(0)}</span>`;
                                            }
                                        }}
                                    />
                                ) : (
                                    <span className="text-2xl font-bold uppercase text-muted-foreground">{lead.username.charAt(0)}</span>
                                )}
                            </div>
                            <div>
                                <a href={lead.profile_url || `https://instagram.com/${lead.username}`} target="_blank" rel="noreferrer" className="text-lg font-bold flex items-center gap-1 hover:underline">
                                    @{lead.username} <ExternalLink size={16} className="text-muted-foreground" />
                                </a>
                                <p className="text-sm text-muted-foreground">
                                    {lead.followers?.toLocaleString() || 0} followers • {lead.engagement_rate || 0}% eng
                                </p>
                                {lead.photo_score && (
                                    <p className="text-xs font-semibold text-primary mt-1">
                                        AI Score: {lead.photo_score}/40
                                    </p>
                                )}
                            </div>
                        </div>
                        <p className="text-sm line-clamp-2 mb-4 flex-1 text-muted-foreground">
                            {lead.bio || "No bio available"}
                        </p>
                        <Button onClick={() => markContacted(lead.Id)} className="w-full flex items-center gap-2">
                            <Mail size={16} /> Mark as Contacted
                        </Button>
                    </div>
                ))}
                {leads.length === 0 && (
                    <div className="col-span-full py-12 text-center text-muted-foreground">
                        No approved leads found. Check your review queue!
                    </div>
                )}
            </div>
        </div>
    );
}
