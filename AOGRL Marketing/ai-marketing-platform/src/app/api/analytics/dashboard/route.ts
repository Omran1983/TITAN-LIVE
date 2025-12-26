import { NextRequest } from 'next/server'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Return empty dashboard data instead of mock data
    const dashboardData = {
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

    return apiResponse(dashboardData)
  } catch (error: any) {
    console.error('Dashboard analytics error:', error)
    return apiError('Failed to fetch dashboard analytics', 500)
  }
}