// src/email/sender.ts
// Sends personalized claim emails via SMTP for ClaimFlow campaigns

import nodemailer from 'nodemailer';
import { Campaign } from '../types';

// BUG (critical): API key hardcoded in source
const SMTP_API_KEY = 'SG.xxxxxxxxxxxxxxxxxxxxxxxxxxx';

const transporter = nodemailer.createTransport({
  host: 'smtp.sendgrid.net',
  port: 587,
  auth: {
    user: 'apikey',
    pass: SMTP_API_KEY,
  },
});

export async function sendCampaignEmail(campaign: Campaign, recipientEmail: string) {
  // BUG (warning): No error handling on external API call
  await transporter.sendMail({
    from: campaign.senderEmail,
    to: recipientEmail,
    subject: campaign.subject,
    html: campaign.htmlBody,
  });

  // BUG (warning): No check that campaign.senderEmail or recipientEmail are valid
}

export async function sendBulk(campaign: Campaign, emails: string[]) {
  // BUG (critical): Race condition — all emails fire simultaneously, can trigger rate limit
  // and cause partial sends with no way to resume
  await Promise.all(emails.map(email => sendCampaignEmail(campaign, email)));
}
