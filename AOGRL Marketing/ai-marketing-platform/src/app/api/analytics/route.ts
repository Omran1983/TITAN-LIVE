import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser } from '@/lib/api-utils'
import { getAIProvider } from '@/lib/ai-providers'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const { searchParams } = new URL(request.url)
    const campaignId = searchParams.get('campaignId')
    const startDate = searchParams.get('startDate')
    const endDate = searchParams.get('endDate')
    const granularity = searchParams.get('granularity') || 'day' // day, week, month
    
    if (!campaignId) {
      return apiError('Campaign ID is required')
    }
    
    // Verify campaign belongs to user's tenant
    const campaign = await prisma.campaign.findFirst({
      where: {
        id: campaignId,
        tenantId: user.tenantId
      }
    })
    
    if (!campaign) {
      return apiError('Campaign not found', 404)
    }
    
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // Last 30 days
    const end = endDate ? new Date(endDate) : new Date()
    
    // Get analytics data from database
    let analytics = await prisma.analytics.findMany({
      where: {
        campaignId,
        date: {
          gte: start,
          lte: end
        }
      },
      orderBy: { date: 'asc' }
    })
    
    // If no data exists, generate mock data
    if (analytics.length === 0) {
      const aiProvider = getAIProvider()
      const mockData = await aiProvider.generateAnalytics(campaignId, { start, end })
      
      // Store generated data
      const days = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24))
      for (let i = 0; i < Math.min(days, mockData.length); i++) {
        const date = new Date(start)
        date.setDate(date.getDate() + i)
        
        await prisma.analytics.upsert({
          where: {
            campaignId_date: {
              campaignId,
              date
            }
          },
          update: mockData[i],
          create: {
            campaignId,
            date,
            ...mockData[i]
          }
        })
      }
      
      // Fetch the stored data
      analytics = await prisma.analytics.findMany({
        where: {
          campaignId,
          date: {
            gte: start,
            lte: end
          }
        },
        orderBy: { date: 'asc' }
      })
    }
    
    // Calculate summary metrics
    const summary = analytics.reduce(
      (acc, curr) => ({
        totalImpressions: acc.totalImpressions + curr.impressions,
        totalClicks: acc.totalClicks + curr.clicks,
        totalConversions: acc.totalConversions + curr.conversions,
        totalSpend: acc.totalSpend + curr.spend,
        totalRevenue: acc.totalRevenue + curr.revenue
      }),
      {
        totalImpressions: 0,
        totalClicks: 0,
        totalConversions: 0,
        totalSpend: 0,
        totalRevenue: 0
      }
    )
    
    const ctr = summary.totalImpressions > 0 ? (summary.totalClicks / summary.totalImpressions) * 100 : 0
    const conversionRate = summary.totalClicks > 0 ? (summary.totalConversions / summary.totalClicks) * 100 : 0
    const cpa = summary.totalConversions > 0 ? summary.totalSpend / summary.totalConversions : 0
    const roas = summary.totalSpend > 0 ? summary.totalRevenue / summary.totalSpend : 0
    
    return apiResponse({
      analytics,
      summary: {
        ...summary,
        ctr: Math.round(ctr * 100) / 100,
        conversionRate: Math.round(conversionRate * 100) / 100,
        cpa: Math.round(cpa * 100) / 100,
        roas: Math.round(roas * 100) / 100
      },
      dateRange: { start, end },
      granularity
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}