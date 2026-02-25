import { Link, useLocation } from 'react-router-dom';
import { Mail, Send, XCircle, List, BarChart3 } from 'lucide-react';
import { useEffect, useState } from 'react';
import { getOutreachCounts } from '../../lib/api';

export function Sidebar() {
    const location = useLocation();
    const [pendingCount, setPendingCount] = useState<number | null>(null);

    useEffect(() => {
        getOutreachCounts()
            .then(c => setPendingCount(c.pending))
            .catch(() => { });
    }, []);

    const navItems = [
        {
            name: 'Review Queue',
            path: '/',
            icon: <Mail className="w-5 h-5" />,
            badge: pendingCount,
        },
        { name: 'Sent', path: '/sent', icon: <Send className="w-5 h-5" /> },
        { name: 'Rejected', path: '/rejected', icon: <XCircle className="w-5 h-5" /> },
        { name: 'All Leads', path: '/all', icon: <List className="w-5 h-5" /> },
        { name: 'Dashboard', path: '/dashboard', icon: <BarChart3 className="w-5 h-5" /> },
    ];

    return (
        <div className="w-64 bg-card border-r h-screen overflow-y-auto flex flex-col">
            <div className="p-6 border-b">
                <h1 className="text-xl font-bold tracking-tight">Creator Scout</h1>
                <p className="text-sm text-muted-foreground">Email Outreach</p>
            </div>
            <nav className="flex-1 p-4 space-y-2">
                {navItems.map((item) => {
                    const isActive = location.pathname === item.path;
                    return (
                        <Link
                            key={item.path}
                            to={item.path}
                            className={`flex items-center justify-between px-3 py-2 rounded-md transition-colors ${isActive
                                ? 'bg-primary text-primary-foreground font-medium'
                                : 'hover:bg-accent hover:text-accent-foreground text-muted-foreground'
                                }`}
                        >
                            <div className="flex items-center space-x-3">
                                {item.icon}
                                <span>{item.name}</span>
                            </div>
                            {'badge' in item && item.badge != null && item.badge > 0 && (
                                <span className="bg-amber-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">
                                    {item.badge}
                                </span>
                            )}
                        </Link>
                    );
                })}
            </nav>
            <div className="p-4 border-t text-xs text-muted-foreground">
                Version 2.0.0
            </div>
        </div>
    );
}
