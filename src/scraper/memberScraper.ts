// src/scraper/memberScraper.ts
// Crawls unclaimed member websites to extract business info for personalization

import axios from 'axios';
import * as cheerio from 'cheerio';

export async function scrapeWebsite(url: string): Promise<{ title: string; description: string; emails: string[] }> {
  // BUG (warning): No timeout set — can hang indefinitely on slow/unresponsive sites
  const response = await axios.get(url);
  // BUG (critical): No error handling — 4xx/5xx throws, crashes the pipeline

  const $ = cheerio.load(response.data);

  const title = $('title').text();
  const description = $('meta[name="description"]').attr('content') || '';

  // Extract email addresses from page text
  const pageText = $('body').text();
  // BUG (warning): Regex captures emails but no deduplication
  const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
  const emails = pageText.match(emailRegex) || [];

  return { title, description, emails };
}

export async function scrapeMultiple(urls: string[]): Promise<any[]> {
  // BUG (critical): No rate limiting — fires all requests simultaneously
  // Could get IP banned or overwhelm small business servers
  return Promise.all(urls.map(url => scrapeWebsite(url)));
}
