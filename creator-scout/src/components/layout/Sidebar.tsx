import { Link, useLocation } from 'react-router-dom';
import { Users, CheckCircle, XCircle, BarChart3, List } from 'lucide-react';

export function Sidebar() {
    const location = useLocation();

    const navItems = [
        { name: 'Review Queue', path: '/', icon: <Users className="w-5 h-5" /> },
        { name: 'Approved', path: '/approved', icon: <CheckCircle className="w-5 h-5" /> },
        { name: 'Rejected', path: '/rejected', icon: <XCircle className="w-5 h-5" /> },
        { name: 'All Leads', path: '/all', icon: <List className="w-5 h-5" /> },
        { name: 'Stats Dashboard', path: '/stats', icon: <BarChart3 className="w-5 h-5" /> },
    ];

    return (
        <div className="w-64 bg-card border-r h-screen overflow-y-auto flex flex-col">
            <div className="p-6 border-b">
                <h1 className="text-xl font-bold tracking-tight">Creator Scout</h1>
                <p className="text-sm text-muted-foreground">Iceland Bubble Base</p>
            </div>
            <nav className="flex-1 p-4 space-y-2">
                {navItems.map((item) => {
                    const isActive = location.pathname === item.path;
                    return (
                        <Link
                            key={item.path}
                            to={item.path}
                            className={`flex items-center space-x-3 px-3 py-2 rounded-md transition-colors ${isActive
                                    ? 'bg-primary text-primary-foreground font-medium'
                                    : 'hover:bg-accent hover:text-accent-foreground text-muted-foreground'
                                }`}
                        >
                            {item.icon}
                            <span>{item.name}</span>
                        </Link>
                    );
                })}
            </nav>
            <div className="p-4 border-t text-xs text-muted-foreground">
                Version 1.0.0
            </div>
        </div>
    );
}
