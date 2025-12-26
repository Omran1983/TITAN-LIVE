import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { aiCreativeService } from '@/lib/ai-creative-service'

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    const { id: generationId } = await params

    if (!generationId) {
      return apiError('Generation ID is required')
    }

    const status = await aiCreativeService.getGenerationStatus(generationId)

    return apiResponse({
      generationId,
      status: status.status,
      progress: status.progress,
      result: status.result,
      error: status.error
    })
  } catch (error: any) {
    console.error('Status check error:', error)
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}