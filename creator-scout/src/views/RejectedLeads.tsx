import { useEffect, useState } from 'react';
import { fetchLeads, updateLead } from '../lib/api';
import type { Lead } from '../types';
import { Button } from '../components/ui/button';
import { X, RotateCcw } from 'lucide-react';
import { makeImageUrl } from '../lib/image-proxy';

export default function RejectedLeads() {
    const [leads, setLeads] = useState<Lead[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadLeads();
    }, []);

    async function loadLeads() {
        setLoading(true);
        try {
            const data = await fetchLeads('rejected', 50);
            setLeads(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }

    const undoReject = async (id: number) => {
        try {
            await updateLead(id, { status: 'new' });
            setLeads(leads.filter(l => l.Id !== id));
        } catch (e) {
            console.error(e);
        }
    };

    if (loading) return <div className="p-8">Loading rejected leads...</div>;

    return (
        <div className="p-8">
            <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold flex items-center gap-2 text-muted-foreground">
                    <X className="text-red-500" />
                    Rejected Creators ({leads.length})
                </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                {leads.map(lead => (
                    <div key={lead.Id} className="border rounded-xl p-4 bg-muted/50 text-card-foreground shadow-sm flex items-center justify-between">
                        <div className="flex items-center gap-3 overflow-hidden">
                            <div className="w-10 h-10 rounded-full bg-muted overflow-hidden flex flex-shrink-0 items-center justify-center opacity-70">
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
                                                parent.innerHTML = `<span class="text-lg font-bold uppercase text-primary">${lead.username.charAt(0)}</span>`;
                                            }
                                        }}
                                    />
                                ) : (
                                    <span className="text-lg font-bold uppercase text-muted-foreground">{lead.username.charAt(0)}</span>
                                )}
                            </div>
                            <div className="overflow-hidden">
                                <a href={lead.profile_url || `https://instagram.com/${lead.username}`} target="_blank" rel="noreferrer" className="font-semibold flex items-center gap-1 hover:underline truncate">
                                    @{lead.username}
                                </a>
                                <p className="text-xs text-muted-foreground">
                                    {lead.followers?.toLocaleString() || 0} followers
                                </p>
                            </div>
                        </div>

                        <Button variant="outline" size="icon" onClick={() => undoReject(lead.Id)} title="Undo (Move to new)" className="flex-shrink-0 text-muted-foreground hover:text-foreground">
                            <RotateCcw size={16} />
                        </Button>
                    </div>
                ))}
                {leads.length === 0 && (
                    <div className="col-span-full py-12 text-center text-muted-foreground">
                        No rejected leads here!
                    </div>
                )}
            </div>
        </div>
    );
}
