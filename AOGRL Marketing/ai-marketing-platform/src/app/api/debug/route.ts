import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Get all creatives with raw content first
    const rawCreatives = await prisma.creative.findMany({
      orderBy: { createdAt: 'desc' }
    })

    console.log('Raw creatives from DB:', rawCreatives.length)

    // Parse content for each creative
    const creativesWithParsedContent = rawCreatives.map(creative => {
      let content = {};
      try {
        content = JSON.parse(creative.content);
        console.log(`Parsed content for ${creative.id}:`, {
          type: typeof content,
          keys: Object.keys(content),
          sample: JSON.stringify(content).substring(0, 100)
        });
      } catch (parseError) {
        console.log(`Failed to parse content for ${creative.id}:`, creative.content);
        content = typeof creative.content === 'string' ? { text: creative.content } : {};
      }
      
      return {
        ...creative,
        content
      };
    });

    // Log summary
    console.log('Creatives summary:');
    creativesWithParsedContent.forEach((c, i) => {
      console.log(`${i+1}. ${c.type} - ${c.status} - ${c.content?.imageUrl ? 'Has imageUrl' : c.content?.result?.url ? 'Has result.url' : 'No image URL'}`);
    });

    return apiResponse({
      creatives: creativesWithParsedContent,
      count: creativesWithParsedContent.length,
      rawCount: rawCreatives.length
    });
  } catch (error: any) {
    console.error('Debug API error:', error);
    return apiError(error.message, 500);
  }
}