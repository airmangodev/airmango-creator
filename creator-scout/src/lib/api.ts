import type { Lead, Post, LeadStatus } from '../types';

const API_TOKEN = import.meta.env.VITE_NOCODB_API_TOKEN;
const PROJECT_ID = 'pfj2wm7mqdy2aje';
const LEADS_TABLE = 'ma36vc2ofr4ozbc';
const POSTS_TABLE = 'mntx3ptd0skk15g';

// In dev, the Vite proxy handles /api -> nocodb. In production, call NocoDB directly.
const NOCODB_HOST = import.meta.env.DEV
    ? '/api/v1/db/data/v1'
    : 'https://nocodb.restaurantreykjavik.com/api/v1/db/data/v1';
const BASE_URL = NOCODB_HOST;

const headers = {
    'xc-token': API_TOKEN,
    'Content-Type': 'application/json'
};

export async function fetchLeads(status: LeadStatus, limit = 25): Promise<Lead[]> {
    const url = `${BASE_URL}/${PROJECT_ID}/${LEADS_TABLE}?where=(status,eq,${status})&limit=${limit}&sort=-CreatedAt`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`Failed to fetch leads: ${res.statusText}`);
    const data = await res.json();
    return data.list;
}

export async function fetchAllLeads(limit = 100): Promise<Lead[]> {
    const url = `${BASE_URL}/${PROJECT_ID}/${LEADS_TABLE}?limit=${limit}&sort=-CreatedAt`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`Failed to fetch leads: ${res.statusText}`);
    const data = await res.json();
    return data.list;
}

export async function updateLead(id: number, data: Partial<Lead>): Promise<Lead> {
    const url = `${BASE_URL}/${PROJECT_ID}/${LEADS_TABLE}/${id}`;
    const res = await fetch(url, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error(`Failed to update lead: ${res.statusText}`);
    return await res.json();
}

export async function fetchUserPosts(username: string, limit = 5): Promise<Post[]> {
    const url = `${BASE_URL}/${PROJECT_ID}/${POSTS_TABLE}?where=(username,eq,${username})&limit=${limit}&sort=-likes`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`Failed to fetch posts: ${res.statusText}`);
    const data = await res.json();
    return data.list;
}

export async function getStats() {
    // To avoid multiple heavy network requests, just get all records and group on client
    // For production, use aggregate endpoints if available
    const leads = await fetchAllLeads(5000);
    const stats = {
        total: leads.length,
        new: leads.filter(l => l.status === 'new').length,
        approved: leads.filter(l => l.status === 'approved').length,
        rejected: leads.filter(l => l.status === 'rejected').length,
        contacted: leads.filter(l => l.status === 'contacted').length,
    };
    return stats;
}
