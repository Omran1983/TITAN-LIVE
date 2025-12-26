import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { getAIProvider, CreativeRequest } from '@/lib/ai-providers'
import { UserRole, CreativeType } from '@prisma/client'

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    const { type, prompt, productIds, audience } = body as CreativeRequest

    if (!type || !prompt) {
      return apiError('Type and prompt are required')
    }

    // Create pending creative record
    const creative = await prisma.creative.create({
      data: {
        type: type as CreativeType,
        prompt,
        status: 'GENERATING',
        tenantId: user.tenantId,
        content: JSON.stringify({})
      }
    })

    try {
      // Generate creative using AI provider
      const aiProvider = getAIProvider()
      const result = await aiProvider.generateCreative({ type, prompt, productIds, audience })
      
      // Update creative with generated content
      const updatedCreative = await prisma.creative.update({
        where: { id: creative.id },
        data: {
          status: 'COMPLETED',
          content: JSON.stringify(result.content)
        }
      })

      // Log audit
      await prisma.auditLog.create({
        data: {
          userId: user.id,
          tenantId: user.tenantId,
          action: 'CREATE',
          resource: 'creative',
          resourceId: creative.id,
          details: JSON.stringify({ type, prompt })
        }
      })

      return apiResponse({
        ...updatedCreative,
        content: result.content
      }, 201)
    } catch (error: any) {
      // Update creative status to failed
      await prisma.creative.update({
        where: { id: creative.id },
        data: {
          status: 'FAILED',
          content: JSON.stringify({ error: error.message })
        }
      })
      
      return apiError(`Creative generation failed: ${error.message}`, 500)
    }
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const type = searchParams.get('type')
    const status = searchParams.get('status')

    const where: any = {
      tenantId: user.tenantId
    }
    
    if (type) where.type = type
    if (status) where.status = status

    const [creatives, total] = await Promise.all([
      prisma.creative.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.creative.count({ where })
    ])

    // Parse content JSON for each creative
    const creativesWithParsedContent = creatives.map(creative => {
      let content = {};
      try {
        content = JSON.parse(creative.content);
      } catch (parseError) {
        // If parsing fails, use the content as-is or provide a default
        content = typeof creative.content === 'string' ? { text: creative.content } : {};
      }
      
      return {
        ...creative,
        content
      };
    });

    return apiResponse({
      creatives: creativesWithParsedContent,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}