import type { Lead, Post, LeadStatus, OutreachLead, OutreachStatus } from '../types';

const API_TOKEN = import.meta.env.VITE_NOCODB_API_TOKEN;
const PROJECT_ID = 'pfj2wm7mqdy2aje';
const LEADS_TABLE = 'ma36vc2ofr4ozbc';
const POSTS_TABLE = 'mntx3ptd0skk15g';
const OUTREACH_TABLE = import.meta.env.VITE_OUTREACH_TABLE_ID || 'm4rmcypybbwgk2b';
const SEND_WEBHOOK = import.meta.env.VITE_SEND_EMAIL_WEBHOOK || 'https://n8n.restaurantreykjavik.com/webhook/content-leads-mail-outreach';

// In dev, the Vite proxy handles /api -> nocodb. In production, call NocoDB directly.
const NOCODB_HOST = import.meta.env.DEV
    ? '/api/v1/db/data/v1'
    : 'https://nocodb.restaurantreykjavik.com/api/v1/db/data/v1';
const BASE_URL = NOCODB_HOST;

const headers = {
    'xc-token': API_TOKEN,
    'Content-Type': 'application/json'
};

// ──────────────────────────────────────────────
// EXISTING: Scout Leads (kept for backward compat)
// ──────────────────────────────────────────────

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

// ──────────────────────────────────────────────
// NEW: Outreach Queue
// ──────────────────────────────────────────────

/** Fetch outreach leads, optionally filtered by status */
export async function fetchOutreachLeads(status?: OutreachStatus, limit = 200): Promise<OutreachLead[]> {
    let url = `${BASE_URL}/${PROJECT_ID}/${OUTREACH_TABLE}?limit=${limit}&sort=-CreatedAt`;
    if (status) {
        url += `&where=(status,eq,${status})`;
    }
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`Failed to fetch outreach leads: ${res.statusText}`);
    const data = await res.json();
    return data.list || [];
}

/** Update an outreach lead by ID */
export async function updateOutreachLead(
    id: number,
    fields: Partial<OutreachLead>
): Promise<void> {
    const url = `${BASE_URL}/${PROJECT_ID}/${OUTREACH_TABLE}/${id}`;
    const res = await fetch(url, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(fields),
    });
    if (!res.ok) throw new Error(`Failed to update outreach lead: ${res.statusText}`);
}

/** Approve & send: POST to n8n webhook then update NocoDB status to 'sent' */
export async function approveAndSendEmail(
    lead: OutreachLead,
    editedSubject: string,
    editedBody: string
): Promise<void> {
    // 1. Call the n8n webhook to trigger email sending
    await fetch(SEND_WEBHOOK, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            recordId: lead.Id,
            email: lead.email,
            emailSubject: editedSubject,
            emailBody: editedBody,
            username: lead.username,
            profileUrl: lead.profile_url,
        }),
    });

    // 2. Update NocoDB record to 'sent'
    await updateOutreachLead(lead.Id, {
        status: 'sent',
        email_subject: editedSubject,
        email_body: editedBody,
        sent_at: new Date().toISOString(),
    } as any);
}

/** Reject an outreach lead */
export async function rejectOutreachLead(recordId: number): Promise<void> {
    await updateOutreachLead(recordId, {
        status: 'rejected',
        rejected_at: new Date().toISOString(),
    } as any);
}

/** Get pipeline counts for sidebar badge & dashboard */
export async function getOutreachCounts(): Promise<{
    pending: number;
    sent: number;
    rejected: number;
    total: number;
}> {
    const all = await fetchOutreachLeads(undefined, 5000);
    return {
        pending: all.filter(l => l.status === 'pending_approval').length,
        sent: all.filter(l => l.status === 'sent').length,
        rejected: all.filter(l => l.status === 'rejected').length,
        total: all.length,
    };
}

/** Get aggregated stats for the dashboard */
export async function getOutreachStats() {
    const all = await fetchOutreachLeads(undefined, 5000);
    const withEmail = all.length; // all records in outreach_queue have email
    const sentCount = all.filter(l => l.status === 'sent').length;
    const pendingCount = all.filter(l => l.status === 'pending_approval').length;
    const rejectedCount = all.filter(l => l.status === 'rejected').length;

    const scores = all.map(l => l.photo_score).filter((s): s is number => s != null && s > 0);
    const avgScore = scores.length > 0 ? scores.reduce((a, b) => a + b, 0) / scores.length : 0;

    const followers = all.map(l => l.followers).filter((f): f is number => f != null && f > 0);
    const avgFollowers = followers.length > 0 ? followers.reduce((a, b) => a + b, 0) / followers.length : 0;

    return {
        total: all.length,
        withEmail,
        sent: sentCount,
        pending: pendingCount,
        rejected: rejectedCount,
        avgScore: Math.round(avgScore * 10) / 10,
        avgFollowers: Math.round(avgFollowers),
    };
}
