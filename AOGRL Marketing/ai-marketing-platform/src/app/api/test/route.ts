import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    message: 'API is working correctly',
    timestamp: new Date().toISOString(),
    data: {
      revenue: 0,
      campaigns: 0,
      impressions: 0,
      clickRate: 0,
      conversions: 0,
      totalSpend: 0,
      products: 0,
      creatives: 0,
      activeUsers: 0,
      globalReach: 0,
      aiInsights: 0
    }
  })
}