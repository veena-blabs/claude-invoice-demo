// src/ai/competitorDiscovery.ts
// Discovers competitors via Google Custom Search API for FOMO personalization

export async function findCompetitors(businessName: string, industry: string): Promise<string[]> {
  const apiKey = process.env.GOOGLE_API_KEY;
  const cx = process.env.GOOGLE_CX;

  // BUG (critical): No check that apiKey/cx are defined — will send "undefined" as query param
  const url = `https://www.googleapis.com/customsearch/v1?key=${apiKey}&cx=${cx}&q=${businessName}+${industry}+competitors`;
  // BUG (warning): businessName/industry not URL-encoded — spaces break the request

  const response = await fetch(url);
  // BUG (critical): No error handling on fetch — non-200 response not checked

  const data = await response.json() as any;

  return data.items?.map((item: any) => item.title) || [];
}
