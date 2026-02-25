import { useEffect, useState } from 'react';
import { getOutreachStats } from '../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Users, Send, Star, UserCheck } from 'lucide-react';
import { formatNumber } from '../lib/utils';

interface Stats {
    total: number;
    withEmail: number;
    sent: number;
    pending: number;
    rejected: number;
    avgScore: number;
    avgFollowers: number;
}

export default function StatsDashboard() {
    const [stats, setStats] = useState<Stats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadStats();
    }, []);

    async function loadStats() {
        setLoading(true);
        try {
            const data = await getOutreachStats();
            setStats(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    }

    if (loading) return <div className="p-8 text-muted-foreground">Loading dashboard...</div>;
    if (!stats) return <div className="p-8 text-muted-foreground">Failed to load stats.</div>;

    const statCards = [
        {
            title: 'Total Leads',
            value: stats.total.toLocaleString(),
            subtitle: `${stats.withEmail} with email (100%)`,
            icon: <Users className="text-blue-500" />,
        },
        {
            title: 'Emails Sent',
            value: stats.sent.toLocaleString(),
            subtitle: `${stats.pending} pending review`,
            icon: <Send className="text-emerald-500" />,
        },
        {
            title: 'Avg Photo Score',
            value: stats.avgScore.toFixed(1),
            subtitle: 'out of 10',
            icon: <Star className="text-amber-500" />,
        },
        {
            title: 'Avg Followers',
            value: formatNumber(stats.avgFollowers),
            subtitle: 'per creator',
            icon: <UserCheck className="text-purple-500" />,
        },
    ];

    const total = stats.sent + stats.pending + stats.rejected;
    const sentPct = total > 0 ? (stats.sent / total) * 100 : 0;
    const pendingPct = total > 0 ? (stats.pending / total) * 100 : 0;
    const rejectedPct = total > 0 ? (stats.rejected / total) * 100 : 0;

    return (
        <div className="p-8">
            <h2 className="text-2xl font-bold mb-6">Dashboard</h2>

            {/* Stat Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                {statCards.map((stat) => (
                    <Card key={stat.title}>
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-sm font-medium text-muted-foreground">{stat.title}</CardTitle>
                            {stat.icon}
                        </CardHeader>
                        <CardContent>
                            <div className="text-3xl font-bold">{stat.value}</div>
                            <p className="text-xs text-muted-foreground mt-1">{stat.subtitle}</p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Pipeline Bar */}
            <Card>
                <CardHeader>
                    <CardTitle className="text-sm font-medium text-muted-foreground">Pipeline Breakdown</CardTitle>
                </CardHeader>
                <CardContent>
                    {total > 0 ? (
                        <>
                            <div className="w-full h-6 rounded-full overflow-hidden flex bg-muted">
                                {sentPct > 0 && (
                                    <div
                                        className="h-full bg-blue-500 transition-all"
                                        style={{ width: `${sentPct}%` }}
                                        title={`Sent: ${stats.sent}`}
                                    />
                                )}
                                {pendingPct > 0 && (
                                    <div
                                        className="h-full bg-amber-400 transition-all"
                                        style={{ width: `${pendingPct}%` }}
                                        title={`Pending: ${stats.pending}`}
                                    />
                                )}
                                {rejectedPct > 0 && (
                                    <div
                                        className="h-full bg-red-400 transition-all"
                                        style={{ width: `${rejectedPct}%` }}
                                        title={`Rejected: ${stats.rejected}`}
                                    />
                                )}
                            </div>
                            <div className="flex gap-6 mt-3 text-sm">
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-blue-500" />
                                    <span className="text-muted-foreground">Sent ({stats.sent})</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-amber-400" />
                                    <span className="text-muted-foreground">Pending ({stats.pending})</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-red-400" />
                                    <span className="text-muted-foreground">Rejected ({stats.rejected})</span>
                                </div>
                            </div>
                        </>
                    ) : (
                        <p className="text-muted-foreground text-sm">No data yet — pipeline will show as emails are processed.</p>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
