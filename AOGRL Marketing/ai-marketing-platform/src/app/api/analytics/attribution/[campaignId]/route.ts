import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { analyticsService } from '@/lib/analytics-service'

export async function GET(request: NextRequest, { params }: { params: Promise<{ campaignId: string }> }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    const { campaignId } = await params

    const attribution = await analyticsService.generateAttributionAnalysis(campaignId)

    return apiResponse({
      campaignId,
      attribution,
      generatedAt: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}