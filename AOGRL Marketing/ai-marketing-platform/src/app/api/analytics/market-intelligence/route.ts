import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { analyticsService } from '@/lib/analytics-service'

export async function GET(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    
    const { searchParams } = new URL(request.url)
    const industry = searchParams.get('industry') || 'marketing'

    const intelligence = await analyticsService.generateMarketIntelligence(industry)

    return apiResponse({
      industry,
      intelligence,
      generatedAt: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}