import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { budgetOptimizer } from '@/lib/budget-optimizer'

export async function GET(request: NextRequest, { params }: { params: { campaignId: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    const campaignId = params.campaignId
    
    const { searchParams } = new URL(request.url)
    const days = parseInt(searchParams.get('days') || '30')
    
    if (days < 1 || days > 365) {
      return apiError('Days must be between 1 and 365')
    }

    const forecast = await budgetOptimizer.forecastBudgetNeeds(campaignId, days)
    
    return apiResponse({
      campaignId,
      forecast,
      forecastPeriod: `${days} days`,
      generatedAt: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}