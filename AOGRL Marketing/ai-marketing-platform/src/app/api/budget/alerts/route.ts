import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { budgetOptimizer } from '@/lib/budget-optimizer'

export async function GET(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    
    const alerts = await budgetOptimizer.monitorBudgets(user.tenantId)
    
    return apiResponse({
      alerts: alerts.alerts,
      summary: alerts.summary,
      lastUpdated: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}