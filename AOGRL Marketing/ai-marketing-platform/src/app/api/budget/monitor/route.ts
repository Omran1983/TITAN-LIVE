import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'
import { budgetOptimizer } from '@/lib/budget-optimizer'

// This endpoint is for Vercel cron jobs - monitors budget alerts
export async function GET(request: NextRequest) {
  try {
    // Verify this is a cron request (Vercel sets this header)
    const isCronRequest = request.headers.get('x-vercel-cron') === '1'
    if (!isCronRequest) {
      return apiError('This endpoint is only accessible via Vercel cron jobs', 403)
    }
    
    console.log('💰 Starting budget monitoring job...')
    
    // Get all active campaigns with budgets
    const campaigns = await prisma.campaign.findMany({
      where: {
        status: 'RUNNING',
        budget: {
          gt: 0
        }
      },
      include: {
        tenant: true
      }
    })
    
    console.log(`📊 Monitoring budgets for ${campaigns.length} active campaigns`)
    
    let alertsGenerated = 0
    
    // Check each campaign's budget
    for (const campaign of campaigns) {
      try {
        // Get current spend for the campaign (last 24 hours)
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000)
        const analytics = await prisma.analytics.findMany({
          where: {
            campaignId: campaign.id,
            date: {
              gte: yesterday
            }
          }
        })
        
        const totalSpend = analytics.reduce((sum, a) => sum + a.spend, 0)
        
        // Check if spend is approaching budget limits
        const spendPercentage = (totalSpend / campaign.budget) * 100
        
        // Generate alerts for thresholds
        if (spendPercentage >= 90 && spendPercentage < 95) {
          // Warning alert - 90% budget used
          await prisma.auditLog.create({
            data: {
              userId: campaign.createdById,
              tenantId: campaign.tenantId,
              action: 'WARNING',
              resource: 'budget',
              resourceId: campaign.id,
              details: JSON.stringify({
                message: `Campaign "${campaign.name}" has used 90% of its budget`,
                campaignId: campaign.id,
                budget: campaign.budget,
                spent: totalSpend,
                percentage: Math.round(spendPercentage * 100) / 100
              }),
              ipAddress: '127.0.0.1',
              userAgent: 'BudgetMonitor/1.0'
            }
          })
          alertsGenerated++
          console.log(`⚠️  Budget warning for campaign: ${campaign.name} (${Math.round(spendPercentage)}%)`)
        } else if (spendPercentage >= 95) {
          // Critical alert - 95% budget used
          await prisma.auditLog.create({
            data: {
              userId: campaign.createdById,
              tenantId: campaign.tenantId,
              action: 'CRITICAL',
              resource: 'budget',
              resourceId: campaign.id,
              details: JSON.stringify({
                message: `Campaign "${campaign.name}" has used 95% of its budget`,
                campaignId: campaign.id,
                budget: campaign.budget,
                spent: totalSpend,
                percentage: Math.round(spendPercentage * 100) / 100
              }),
              ipAddress: '127.0.0.1',
              userAgent: 'BudgetMonitor/1.0'
            }
          })
          alertsGenerated++
          console.log(`🚨 Critical budget alert for campaign: ${campaign.name} (${Math.round(spendPercentage)}%)`)
        }
      } catch (error) {
        console.error(`❌ Failed to monitor budget for campaign ${campaign.name}:`, error)
        // Continue with other campaigns
      }
    }
    
    return apiResponse({
      message: 'Budget monitoring completed',
      alertsGenerated,
      campaignsMonitored: campaigns.length
    })
  } catch (error: any) {
    console.error('Budget monitoring failed:', error)
    return apiError(`Budget monitoring failed: ${error.message}`, 500)
  }
}