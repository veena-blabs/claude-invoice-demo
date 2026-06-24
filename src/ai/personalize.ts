// src/ai/personalize.ts
// Uses Anthropic Claude to generate personalized email copy for unclaimed listings

import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
  // BUG (critical): No check that API key is set — will fail silently with cryptic SDK error
});

export async function generateEmailCopy(
  businessName: string,
  websiteSummary: string,
  competitorNames: string[]
): Promise<string> {

  // BUG (warning): No input length validation — oversized websiteSummary blows token budget
  const prompt = `
    You are writing a personalized email to ${businessName}.
    Their website summary: ${websiteSummary}
    Competitors in their space: ${competitorNames.join(', ')}
    Write a compelling 3-paragraph email encouraging them to claim their directory listing.
  `;

  // BUG (critical): Unhandled promise — if Anthropic API throws, the whole process crashes
  const response = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    messages: [{ role: 'user', content: prompt }],
  });

  return response.content[0].type === 'text' ? response.content[0].text : '';
}

export async function batchPersonalize(businesses: Array<{ name: string; summary: string; competitors: string[] }>) {
  // BUG (critical): Fires all API calls simultaneously — no rate limiting, can exhaust quota
  const results = await Promise.all(
    businesses.map(b => generateEmailCopy(b.name, b.summary, b.competitors))
  );
  return results;
}
