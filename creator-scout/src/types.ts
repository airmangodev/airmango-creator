export type LeadStatus = 'new' | 'approved' | 'rejected' | 'contacted';

export interface Lead {
    Id: number;
    username: string;
    followers: number;
    bio: string | null;
    profile_url: string | null;
    profile_pic: string | null;
    engagement_rate: number | null;
    avg_likes: number | null;
    best_post_code: string | null;
    best_post_image: string | null;
    best_post_likes: number | null;
    location_name: string | null;
    photo_score: number | null;
    photo_reason: string | null;
    post_images: string | null; // JSON string array
    status: LeadStatus;
    CreatedAt: string;
}

export interface Post {
    Id: number;
    postCode: string;
    username: string;
    caption: string | null;
    likes: number | null;
    comments: number | null;
    image_url: string | null;
    location_name: string | null;
    timestamp: string | null;
}
