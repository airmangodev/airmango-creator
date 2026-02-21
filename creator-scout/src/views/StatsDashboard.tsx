import { useEffect, useState } from 'react';
import { getStats } from '../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Users, UserPlus, UserCheck, UserX, UserMinus } from 'lucide-react';

export default function StatsDashboard() {
    const [stats, setStats] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadStats();
    }, []);

    async function loadStats() {
        setLoading(true);
        try {
            const data = await getStats();
            setStats(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    }

    if (loading) return <div className="p-8">Loading stats...</div>;
    if (!stats) return <div className="p-8">Failed to load stats.</div>;

    const statCards = [
        { title: 'Total Scraped', value: stats.total, icon: <Users /> },
        { title: 'New (In Queue)', value: stats.new, icon: <UserPlus className="text-blue-500" /> },
        { title: 'Approved', value: stats.approved, icon: <UserCheck className="text-green-500" /> },
        { title: 'Rejected', value: stats.rejected, icon: <UserX className="text-red-500" /> },
        { title: 'Contacted', value: stats.contacted, icon: <UserMinus className="text-purple-500" /> },
    ];

    return (
        <div className="p-8">
            <h2 className="text-2xl font-bold mb-6">Stats Dashboard</h2>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6">
                {statCards.map((stat) => (
                    <Card key={stat.title}>
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-sm font-medium text-muted-foreground">{stat.title}</CardTitle>
                            {stat.icon}
                        </CardHeader>
                        <CardContent>
                            <div className="text-3xl font-bold">{stat.value.toLocaleString()}</div>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    );
}
