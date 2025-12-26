import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { aiCreativeService } from '@/lib/ai-creative-service'

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { type, prompt, style, dimensions, duration, voice, tone, language, brand } = body

    if (!type || !prompt) {
      return apiError('Type and prompt are required')
    }

    // Validate prompt length
    if (prompt.length < 10) {
      return apiError('Prompt must be at least 10 characters long')
    }

    // Create creative record in database first
    const creative = await prisma.creative.create({
      data: {
        type: type.toUpperCase(),
        content: JSON.stringify({ prompt, style, dimensions, duration, voice, tone, language }),
        prompt,
        status: 'GENERATING',
        tenantId: user.tenantId
      }
    })

    // Start AI generation process
    let generationResult
    try {
      switch (type) {
        case 'image':
          generationResult = await aiCreativeService.generateImage({
            type, prompt, style, dimensions, brand
          })
          break
        case 'video':
          generationResult = await aiCreativeService.generateVideo({
            type, prompt, style, dimensions, duration, brand
          })
          break
        case 'audio':
          generationResult = await aiCreativeService.generateAudio({
            type, prompt, voice, duration, language, brand
          })
          break
        case 'copy':
          generationResult = await aiCreativeService.generateCopy({
            type, prompt, tone, language, brand
          })
          break
        default:
          return apiError('Invalid creative type')
      }
    } catch (generationError: any) {
      // Update creative status to failed if generation fails
      await prisma.creative.update({
        where: { id: creative.id },
        data: {
          status: 'FAILED',
          content: JSON.stringify({
            ...JSON.parse(creative.content),
            error: generationError.message || 'Generation failed'
          })
        }
      })
      
      throw new Error(`AI Generation failed: ${generationError.message || 'Unknown error'}`)
    }

    // Update creative with generation result
    const updatedCreative = await prisma.creative.update({
      where: { id: creative.id },
      data: {
        status: generationResult.status === 'completed' ? 'COMPLETED' : 'GENERATING',
        content: JSON.stringify({
          ...JSON.parse(creative.content),
          generationId: generationResult.id,
          result: generationResult.result,
          progress: generationResult.progress
        })
      }
    })

    // Create scheduled job for status tracking if still processing
    if (generationResult.status === 'processing') {
      await prisma.scheduledJob.create({
        data: {
          jobId: `creative-generation-${creative.id}`,
          type: 'CREATIVE_GENERATION',
          payload: JSON.stringify({ 
            creativeId: creative.id, 
            generationId: generationResult.id 
          }),
          scheduledAt: new Date(Date.now() + 30000), // Check in 30 seconds
          status: 'PENDING'
        }
      })
    }

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'CREATE',
        resource: 'creative',
        resourceId: creative.id,
        details: JSON.stringify({ type, prompt: prompt.substring(0, 100) })
      }
    })

    return apiResponse({
      message: 'Creative generation started',
      creative: {
        ...updatedCreative,
        content: JSON.parse(updatedCreative.content || '{}')
      },
      generationId: generationResult.id,
      status: generationResult.status,
      progress: generationResult.progress
    }, 201)
  } catch (error: any) {
    console.error('Creative generation error:', error)
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}