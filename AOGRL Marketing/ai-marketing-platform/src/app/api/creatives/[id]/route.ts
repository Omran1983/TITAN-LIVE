import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

// GET /api/creatives/[id] - Get a specific creative by ID
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await getAuthenticatedUser()
    const { id } = params

    if (!id) {
      return apiError('Creative ID is required', 400)
    }

    const creative = await prisma.creative.findFirst({
      where: {
        id,
        tenantId: user.tenantId
      }
    })

    if (!creative) {
      return apiError('Creative not found', 404)
    }

    // Parse content JSON
    let content = {};
    try {
      content = JSON.parse(creative.content);
    } catch (parseError) {
      content = typeof creative.content === 'string' ? { text: creative.content } : {};
    }

    return apiResponse({
      ...creative,
      content
    });
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

// PUT /api/creatives/[id] - Update a creative
export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const { id } = params
    const body = await request.json()
    const { content, prompt, status } = body

    if (!id) {
      return apiError('Creative ID is required', 400)
    }

    // Check if creative exists and belongs to user's tenant
    const existingCreative = await prisma.creative.findFirst({
      where: {
        id,
        tenantId: user.tenantId
      }
    })

    if (!existingCreative) {
      return apiError('Creative not found', 404)
    }

    // Update creative
    const updatedCreative = await prisma.creative.update({
      where: { id },
      data: {
        content: content ? JSON.stringify(content) : existingCreative.content,
        prompt: prompt || existingCreative.prompt,
        status: status || existingCreative.status
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'UPDATE',
        resource: 'creative',
        resourceId: id,
        details: JSON.stringify({ updatedFields: Object.keys(body) })
      }
    })

    // Parse content JSON for response
    let parsedContent = {};
    try {
      parsedContent = JSON.parse(updatedCreative.content);
    } catch (parseError) {
      parsedContent = typeof updatedCreative.content === 'string' ? { text: updatedCreative.content } : {};
    }

    return apiResponse({
      ...updatedCreative,
      content: parsedContent
    });
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

// DELETE /api/creatives/[id] - Delete a creative
export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const { id } = params

    if (!id) {
      return apiError('Creative ID is required', 400)
    }

    // Check if creative exists and belongs to user's tenant
    const existingCreative = await prisma.creative.findFirst({
      where: {
        id,
        tenantId: user.tenantId
      }
    })

    if (!existingCreative) {
      return apiError('Creative not found', 404)
    }

    // Delete creative
    await prisma.creative.delete({
      where: { id }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'DELETE',
        resource: 'creative',
        resourceId: id,
        details: JSON.stringify({ name: existingCreative.prompt?.substring(0, 50) })
      }
    })

    return apiResponse({ message: 'Creative deleted successfully' });
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}