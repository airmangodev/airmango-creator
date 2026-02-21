import { Sidebar } from './Sidebar';
import { Outlet } from 'react-router-dom';

export function Layout() {
    return (
        <div className="flex h-screen w-full bg-background text-foreground overflow-hidden">
            <div className="hidden md:block">
                <Sidebar />
            </div>
            <main className="flex-1 overflow-y-auto relative">
                {/* Mobile Nav Header could go here */}
                <div className="md:hidden flex items-center p-4 border-b bg-card">
                    <h1 className="text-lg font-bold">Creator Scout</h1>
                </div>
                <div className="h-full">
                    <Outlet />
                </div>
            </main>
        </div>
    );
}
