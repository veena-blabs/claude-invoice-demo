// src/routes/dashboard.ts
// Dashboard API endpoints — stats for the 3-page Express dashboard

import { Router, Request, Response } from 'express';
import { db } from '../db/connection';

const router = Router();

// BUG (critical): No authentication middleware on dashboard routes
router.get('/stats/overview', async (_req: Request, res: Response) => {
  const totalCampaigns = await db.query('SELECT COUNT(*) FROM campaigns');
  const totalSent = await db.query('SELECT COUNT(*) FROM sent_emails');
  const totalConverted = await db.query('SELECT COUNT(*) FROM conversions');

  // BUG (warning): Division without zero-check — crashes if totalSent is 0
  const conversionRate = totalConverted / totalSent;

  res.json({ totalCampaigns, totalSent, totalConverted, conversionRate });
});

router.get('/stats/costs', async (req: Request, res: Response) => {
  // BUG (warning): date params from query string used directly in SQL without sanitization
  const { from, to } = req.query;
  const costs = await db.query(
    `SELECT * FROM token_usage WHERE created_at BETWEEN '${from}' AND '${to}'`
  );
  res.json(costs);
});

export default router;
