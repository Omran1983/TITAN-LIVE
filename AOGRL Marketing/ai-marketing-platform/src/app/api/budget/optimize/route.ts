import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { budgetOptimizer } from '@/lib/budget-optimizer'

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { 
      campaignIds,
      totalBudget,
      currency = 'USD',
      timeframe = 'monthly',
      objectives,
      constraints
    } = body

    if (!totalBudget || !objectives) {
      return apiError('Total budget and objectives are required')
    }

    if (totalBudget <= 0) {
      return apiError('Total budget must be greater than 0')
    }

    // Validate objectives
    const validObjectives = ['conversions', 'reach', 'engagement', 'revenue']
    if (!validObjectives.includes(objectives.primary)) {
      return apiError('Invalid primary objective')
    }

    const optimizationRequest = {
      campaignIds,
      totalBudget,
      currency,
      timeframe,
      objectives,
      constraints
    }

    // Run budget optimization
    const result = await budgetOptimizer.optimizeBudget(optimizationRequest, user.tenantId)

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'CREATE',
        resource: 'budget_optimization',
        resourceId: `opt-${Date.now()}`,
        details: JSON.stringify({ 
          totalBudget, 
          campaignCount: result.recommendations.length,
          objective: objectives.primary
        })
      }
    })

    return apiResponse({
      message: 'Budget optimization completed successfully',
      optimization: result,
      metadata: {
        campaignsAnalyzed: result.recommendations.length,
        totalBudget,
        currency,
        timeframe,
        objective: objectives.primary
      }
    })
  } catch (error: any) {
    console.error('Budget optimization error:', error)
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function GET(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    
    // Get budget monitoring data
    const monitoring = await budgetOptimizer.monitorBudgets(user.tenantId)
    
    return apiResponse({
      monitoring,
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}