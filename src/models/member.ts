// src/models/member.ts
// Member model — represents an unclaimed directory listing

import { db } from '../db/connection';

export interface Member {
  id: string;
  businessName: string;
  websiteUrl: string;
  email: string;
  claimed: boolean;
  campaignId?: string;
}

export async function getMember(id: string): Promise<Member> {
  // BUG (critical): No null check — returns undefined if not found, but return type says Member
  const member = await db.query('SELECT * FROM members WHERE id = $1', [id]);
  return member[0];
}

export async function markClaimed(id: string): Promise<void> {
  // BUG (warning): No check that member exists before updating
  // BUG (warning): No idempotency — calling twice is fine for DB but no confirmation returned
  await db.query('UPDATE members SET claimed = true WHERE id = $1', [id]);
}

export async function getUnclaimedForCampaign(campaignId: string): Promise<Member[]> {
  return db.query(
    'SELECT * FROM members WHERE campaign_id = $1 AND claimed = false',
    [campaignId]
    // style: variable name is fine — not flagging
  );
}
