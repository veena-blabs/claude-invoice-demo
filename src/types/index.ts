// src/types/index.ts
// Shared TypeScript types for ClaimFlow

export interface Campaign {
  id: string;
  name: string;
  senderEmail: string;
  subject: string;
  htmlBody: string;
  status: 'draft' | 'running' | 'completed' | 'failed';
  createdAt: Date;
}

export interface Member {
  id: string;
  businessName: string;
  websiteUrl: string;
  email: string;
  claimed: boolean;
  campaignId?: string;
  websiteSummary?: string;
  competitors?: string[];
}

export interface TokenUsage {
  campaignId: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
}

export interface ReviewFinding {
  file: string;
  line: number | string;
  severity: 'critical' | 'warning' | 'info';
  issue: string;
  fix: string;
}
