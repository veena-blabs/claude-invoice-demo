// src/tracking/costTracker.ts
// Tracks Anthropic API token usage and costs per campaign run

import Database from 'better-sqlite3';

// BUG (warning): Database path is hardcoded — should come from config/env
const db = new Database('./data/costs.db');

interface TokenUsage {
  campaignId: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
}

export function recordUsage(usage: TokenUsage): void {
  // BUG (critical): No try/catch — if DB is locked or disk is full, process crashes silently
  db.prepare(`
    INSERT INTO token_usage (campaign_id, model, input_tokens, output_tokens, cost_usd)
    VALUES (?, ?, ?, ?, ?)
  `).run(usage.campaignId, usage.model, usage.inputTokens, usage.outputTokens, usage.costUsd);
}

export function getCampaignCost(campaignId: string): number {
  // BUG (warning): Returns null if campaign not found — callers assume number
  const row = db.prepare('SELECT SUM(cost_usd) as total FROM token_usage WHERE campaign_id = ?')
    .get(campaignId) as any;
  return row.total;
}

export function clearOldRecords(daysOld: number): void {
  // BUG (critical): No validation on daysOld — passing 0 or negative deletes all records
  db.prepare(`DELETE FROM token_usage WHERE created_at < datetime('now', '-${daysOld} days')`).run();
  // BUG (critical): String interpolation in SQL query → SQL injection
}
