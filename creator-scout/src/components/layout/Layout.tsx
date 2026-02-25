import { Sidebar } from './Sidebar';
import { Outlet } from 'react-router-dom';
import { ToastContainer } from '../ui/Toast';

export function Layout() {
    return (
        <div className="flex h-screen w-full bg-background text-foreground overflow-hidden">
            <div className="hidden md:block">
                <Sidebar />
            </div>
            <main className="flex-1 overflow-y-auto relative">
                {/* Mobile Nav Header */}
                <div className="md:hidden flex items-center p-4 border-b bg-card">
                    <h1 className="text-lg font-bold">Email Outreach</h1>
                </div>
                <div className="h-full">
                    <Outlet />
                </div>
            </main>
            <ToastContainer />
        </div>
    );
}
