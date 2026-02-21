import { useEffect, useState } from 'react';
import { fetchAllLeads } from '../lib/api';
import type { Lead } from '../types';
import { Badge } from '../components/ui/badge';
import { ExternalLink } from 'lucide-react';
import { makeImageUrl } from '../lib/image-proxy';

export default function AllLeads() {
    const [leads, setLeads] = useState<Lead[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadLeads();
    }, []);

    async function loadLeads() {
        try {
            const data = await fetchAllLeads(100);
            setLeads(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'new': return <Badge variant="secondary">New</Badge>;
            case 'approved': return <Badge className="bg-green-500 text-white hover:bg-green-600">Approved</Badge>;
            case 'rejected': return <Badge variant="destructive">Rejected</Badge>;
            case 'contacted': return <Badge variant="outline" className="border-green-500 text-green-500">Contacted</Badge>;
            default: return <Badge>{status}</Badge>;
        }
    }

    if (loading) return <div className="p-8">Loading...</div>;

    return (
        <div className="p-8">
            <h2 className="text-2xl font-bold mb-6 flex justify-between">
                All Leads (Latest 100)
                <Badge variant="outline">{leads.length} leads</Badge>
            </h2>
            <div className="border rounded-lg overflow-hidden bg-card text-card-foreground">
                <table className="w-full text-sm text-left">
                    <thead className="bg-muted text-muted-foreground">
                        <tr>
                            <th className="px-6 py-3">Profile</th>
                            <th className="px-6 py-3">Followers</th>
                            <th className="px-6 py-3">Eng. Rate</th>
                            <th className="px-6 py-3">Status</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y">
                        {leads.map(lead => (
                            <tr key={lead.Id} className="hover:bg-accent hover:text-accent-foreground transition-colors">
                                <td className="px-6 py-4 flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-full bg-muted overflow-hidden flex flex-shrink-0 items-center justify-center">
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
                                    <div>
                                        <a href={lead.profile_url || `https://instagram.com/${lead.username}`} target="_blank" rel="noreferrer" className="font-semibold flex items-center gap-1 hover:underline">
                                            @{lead.username} <ExternalLink size={14} className="text-muted-foreground" />
                                        </a>
                                        <div className="text-xs text-muted-foreground">{lead.location_name || 'No location'}</div>
                                    </div>
                                </td>
                                <td className="px-6 py-4 font-medium">{lead.followers?.toLocaleString() || 0}</td>
                                <td className="px-6 py-4">{lead.engagement_rate || 0}%</td>
                                <td className="px-6 py-4">{getStatusBadge(lead.status)}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
