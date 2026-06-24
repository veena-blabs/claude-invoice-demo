// src/reporting/reportGenerator.ts
// Generates JSON + Markdown cost/conversion reports after each campaign run

import * as fs from 'fs';
import { getCampaignCost } from '../tracking/costTracker';

export async function generateReport(campaignId: string, outputDir: string): Promise<void> {
  const cost = getCampaignCost(campaignId);

  const report = {
    campaignId,
    generatedAt: new Date().toISOString(),
    totalCostUsd: cost,
    // BUG (warning): No sent/opened/converted counts included — report is incomplete
  };

  // BUG (warning): No check that outputDir exists before writing
  // BUG (critical): No error handling on fs.writeFileSync — crashes if disk full or no permission
  fs.writeFileSync(`${outputDir}/${campaignId}.json`, JSON.stringify(report, null, 2));

  const markdown = `# Campaign Report: ${campaignId}\n\n` +
    `**Generated:** ${report.generatedAt}\n\n` +
    `**Total Cost:** $${cost?.toFixed(4)}\n`;
    // BUG (warning): cost?.toFixed(4) — optional chain here means cost could be null,
    // which would render "undefined" in the markdown silently

  fs.writeFileSync(`${outputDir}/${campaignId}.md`, markdown);
}
