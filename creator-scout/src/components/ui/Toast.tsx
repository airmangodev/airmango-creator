import { useEffect, useState } from 'react';

interface ToastItem {
    id: number;
    message: string;
    type: 'success' | 'error' | 'info';
}

let toastId = 0;
let addToastFn: ((toast: Omit<ToastItem, 'id'>) => void) | null = null;

/** Call this from anywhere to show a toast */
export function showToast(message: string, type: 'success' | 'error' | 'info' = 'success') {
    addToastFn?.({ message, type });
}

/** Place this component once at the root of your app */
export function ToastContainer() {
    const [toasts, setToasts] = useState<ToastItem[]>([]);

    useEffect(() => {
        addToastFn = (toast) => {
            const id = ++toastId;
            setToasts(prev => [...prev, { ...toast, id }]);
            setTimeout(() => {
                setToasts(prev => prev.filter(t => t.id !== id));
            }, 3000);
        };
        return () => { addToastFn = null; };
    }, []);

    if (toasts.length === 0) return null;

    return (
        <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2">
            {toasts.map(toast => (
                <div
                    key={toast.id}
                    className={`px-4 py-3 rounded-lg shadow-lg text-sm font-medium text-white animate-slide-up ${toast.type === 'success' ? 'bg-emerald-600' :
                            toast.type === 'error' ? 'bg-red-600' :
                                'bg-blue-600'
                        }`}
                    style={{
                        animation: 'slideUp 0.3s ease-out',
                    }}
                >
                    {toast.message}
                </div>
            ))}
        </div>
    );
}
