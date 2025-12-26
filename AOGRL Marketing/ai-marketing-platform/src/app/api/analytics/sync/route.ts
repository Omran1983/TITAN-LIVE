import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'
import { getAIProvider } from '@/lib/ai-providers'

// This endpoint is for Vercel cron jobs - syncs analytics data
export async function GET(request: NextRequest) {
  try {
    // Verify this is a cron request (Vercel sets this header)
    const isCronRequest = request.headers.get('x-vercel-cron') === '1'
    if (!isCronRequest) {
      return apiError('This endpoint is only accessible via Vercel cron jobs', 403)
    }
    
    console.log('🔄 Starting analytics sync job...')
    
    // Get all active campaigns
    const campaigns = await prisma.campaign.findMany({
      where: {
        status: 'RUNNING'
      },
      include: {
        tenant: true
      }
    })
    
    console.log(`📊 Found ${campaigns.length} active campaigns to sync`)
    
    let syncedCount = 0
    
    // Sync analytics for each campaign
    for (const campaign of campaigns) {
      try {
        // Get date range for sync (last 24 hours)
        const endDate = new Date()
        const startDate = new Date(endDate.getTime() - 24 * 60 * 60 * 1000)
        
        // Generate analytics data using AI provider
        const aiProvider = getAIProvider()
        const analyticsData = await aiProvider.generateAnalytics(campaign.id, { 
          start: startDate, 
          end: endDate 
        })
        
        // Store generated data
        for (const data of analyticsData) {
          const date = new Date(data.date)
          
          await prisma.analytics.upsert({
            where: {
              campaignId_date: {
                campaignId: campaign.id,
                date
              }
            },
            update: data,
            create: {
              campaignId: campaign.id,
              date,
              ...data
            }
          })
        }
        
        syncedCount++
        console.log(`✅ Synced analytics for campaign ${campaign.name}`)
      } catch (error) {
        console.error(`❌ Failed to sync analytics for campaign ${campaign.name}:`, error)
        // Continue with other campaigns
      }
    }
    
    return apiResponse({
      message: 'Analytics sync completed',
      campaignsSynced: syncedCount,
      totalCampaigns: campaigns.length
    })
  } catch (error: any) {
    console.error('Analytics sync failed:', error)
    return apiError(`Analytics sync failed: ${error.message}`, 500)
  }
}