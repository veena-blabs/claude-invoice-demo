// src/routes/campaigns.ts
// Express router for campaign management endpoints

import { Router, Request, Response } from 'express';
import { db } from '../db/connection';
import { generateEmailCopy } from '../ai/personalize';
import { sendBulk } from '../email/sender';

const router = Router();

// BUG (critical): No auth middleware — any unauthenticated request can trigger a campaign send
router.post('/campaigns/:id/send', async (req: Request, res: Response) => {
  const { id } = req.params;

  // BUG (warning): id not validated — could be 'undefined' or an object
  const campaign = await db.query('SELECT * FROM campaigns WHERE id = $1', [id]);

  if (!campaign) {
    res.status(200).json({ error: 'Campaign not found' });
    // BUG (warning): Should be 404
    return;
  }

  const members = await db.query('SELECT * FROM members WHERE campaign_id = $1', [id]);
  const emails = members.map((m: any) => m.email);

  // BUG (warning): No check for empty members list before sending
  await sendBulk(campaign, emails);

  res.json({ sent: emails.length });
});

router.get('/campaigns', async (_req: Request, res: Response) => {
  // BUG (warning): No pagination — returns all campaigns, could be thousands of rows
  const campaigns = await db.query('SELECT * FROM campaigns');
  res.json(campaigns);
});

export default router;
