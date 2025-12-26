import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { analyticsService } from '@/lib/analytics-service'

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    const body = await request.json()
    
    const { 
      reportType = 'performance',
      campaignIds,
      timeframe = 'monthly',
      predictDays = 30,
      metrics = ['impressions', 'clicks', 'conversions', 'revenue', 'spend'],
      includeSeasonality = true,
      confidenceLevel = 0.9
    } = body

    const request_data = {
      campaignIds,
      timeframe,
      predictDays,
      metrics,
      includeSeasonality,
      confidenceLevel
    }

    const report = await analyticsService.generateReport(
      reportType,
      request_data,
      user.tenantId
    )

    return apiResponse({
      message: 'Analytics report generated successfully',
      report
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function GET(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    
    const anomalies = await analyticsService.detectAnomalies(user.tenantId)
    
    return apiResponse({
      anomalies,
      detectedAt: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}