// src/queue/campaignQueue.ts
// Bull queue processor for async campaign execution

import Queue from 'bull';
import { generateEmailCopy } from '../ai/personalize';
import { sendCampaignEmail } from '../email/sender';
import { recordUsage } from '../tracking/costTracker';

// BUG (critical): Redis URL hardcoded — should be from env
const campaignQueue = new Queue('campaigns', 'redis://localhost:6379');

campaignQueue.process(async (job) => {
  const { campaignId, member, campaign } = job.data;

  // BUG (warning): No validation that job.data has required fields
  const emailCopy = await generateEmailCopy(
    member.businessName,
    member.websiteSummary,
    member.competitors
  );

  await sendCampaignEmail({ ...campaign, htmlBody: emailCopy }, member.email);

  // BUG (warning): Token usage hardcoded as 0 — not actually tracking costs
  recordUsage({
    campaignId,
    model: 'claude-sonnet-4-6',
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
  });
});

export default campaignQueue;
