import { useEffect, useState } from 'react';
import { fetchOutreachLeads } from '../lib/api';
import type { OutreachLead } from '../types';
import { Badge } from '../components/ui/badge';
import { ExternalLink } from 'lucide-react';
import { makeImageUrl } from '../lib/image-proxy';
import { formatNumber } from '../lib/utils';

function getStatusBadge(status: string) {
    switch (status) {
        case 'pending_approval': return <Badge className="bg-amber-100 text-amber-800 hover:bg-amber-200">Pending</Badge>;
        case 'approved': return <Badge className="bg-blue-100 text-blue-800 hover:bg-blue-200">Approved</Badge>;
        case 'sent': return <Badge className="bg-blue-500 text-white hover:bg-blue-600">Sent</Badge>;
        case 'rejected': return <Badge variant="destructive">Rejected</Badge>;
        default: return <Badge>{status}</Badge>;
    }
}

export default function AllLeads() {
    const [leads, setLeads] = useState<OutreachLead[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadLeads();
    }, []);

    async function loadLeads() {
        try {
            const data = await fetchOutreachLeads(undefined, 200);
            setLeads(data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }

    if (loading) return <div className="p-8 text-muted-foreground">Loading all leads...</div>;

    return (
        <div className="p-8">
            <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold">All Leads</h2>
                <Badge variant="outline">{leads.length} leads</Badge>
            </div>
            <div className="border rounded-lg overflow-hidden bg-card text-card-foreground">
                <table className="w-full text-sm text-left">
                    <thead className="bg-muted text-muted-foreground">
                        <tr>
                            <th className="px-6 py-3">Creator</th>
                            <th className="px-6 py-3">Email</th>
                            <th className="px-6 py-3">Followers</th>
                            <th className="px-6 py-3">Eng Rate</th>
                            <th className="px-6 py-3">Photo Score</th>
                            <th className="px-6 py-3">Location</th>
                            <th className="px-6 py-3">Status</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y">
                        {leads.map(lead => (
                            <tr key={lead.Id} className="hover:bg-accent hover:text-accent-foreground transition-colors">
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-9 h-9 rounded-full bg-muted overflow-hidden flex-shrink-0 flex items-center justify-center">
                                            {lead.profile_pic ? (
                                                <img
                                                    src={makeImageUrl(lead.profile_pic)}
                                                    className="w-full h-full object-cover"
                                                    referrerPolicy="no-referrer"
                                                    onError={(e) => {
                                                        (e.target as HTMLImageElement).style.display = 'none';
                                                        const parent = (e.target as HTMLImageElement).parentElement;
                                                        if (parent) {
                                                            parent.innerHTML = `<span class="text-sm font-bold uppercase text-muted-foreground">${lead.username.charAt(0)}</span>`;
                                                        }
                                                    }}
                                                />
                                            ) : (
                                                <span className="text-sm font-bold uppercase text-muted-foreground">{lead.username.charAt(0)}</span>
                                            )}
                                        </div>
                                        <a href={lead.profile_url || `https://instagram.com/${lead.username}`} target="_blank" rel="noreferrer" className="font-semibold flex items-center gap-1 hover:underline">
                                            @{lead.username} <ExternalLink size={13} className="text-muted-foreground" />
                                        </a>
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-muted-foreground">{lead.email}</td>
                                <td className="px-6 py-4 font-medium">{formatNumber(lead.followers)}</td>
                                <td className="px-6 py-4">{lead.engagement_rate || 0}%</td>
                                <td className="px-6 py-4">{lead.photo_score != null ? `${lead.photo_score}/10` : '—'}</td>
                                <td className="px-6 py-4 text-muted-foreground">{lead.location_name || '—'}</td>
                                <td className="px-6 py-4">{getStatusBadge(lead.status)}</td>
                            </tr>
                        ))}
                        {leads.length === 0 && (
                            <tr><td colSpan={7} className="px-6 py-12 text-center text-muted-foreground">No leads in outreach queue.</td></tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
