import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { aiCreativeService } from '@/lib/ai-creative-service'

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { type, prompt, count = 3, brand } = body

    if (!type || !prompt) {
      return apiError('Type and prompt are required')
    }

    // Validate prompt length
    if (prompt.length < 10) {
      return apiError('Prompt must be at least 10 characters long')
    }

    if (count > 10) {
      return apiError('Maximum 10 variations allowed per request')
    }

    // Generate variations
    const variations = await aiCreativeService.generateVariations({
      type, prompt, brand
    }, count)

    return apiResponse({
      message: `${count} variations generation started`,
      variations: variations.map(v => ({
        id: v.id,
        status: v.status,
        progress: v.progress,
        error: v.error
      }))
    })
  } catch (error: any) {
    console.error('Variations generation error:', error)
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}