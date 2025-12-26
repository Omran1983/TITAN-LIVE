import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getAuthenticatedUser()
    const product = await prisma.product.findFirst({
      where: {
        id: params.id,
        tenantId: user.tenantId
      }
    })

    if (!product) {
      return apiError('Product not found', 404)
    }

    return apiResponse(product)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    const { name, description, price, imageUrl, category, isActive } = body

    const existingProduct = await prisma.product.findFirst({
      where: {
        id: params.id,
        tenantId: user.tenantId
      }
    })

    if (!existingProduct) {
      return apiError('Product not found', 404)
    }

    const product = await prisma.product.update({
      where: { id: params.id },
      data: {
        name: name || existingProduct.name,
        description: description !== undefined ? description : existingProduct.description,
        price: price ? parseFloat(price) : existingProduct.price,
        imageUrl: imageUrl !== undefined ? imageUrl : existingProduct.imageUrl,
        category: category !== undefined ? category : existingProduct.category,
        isActive: isActive !== undefined ? isActive : existingProduct.isActive
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'UPDATE',
        resource: 'product',
        resourceId: product.id,
        details: JSON.stringify({ changes: body })
      }
    })

    return apiResponse(product)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireRole([UserRole.ADMIN])
    
    const existingProduct = await prisma.product.findFirst({
      where: {
        id: params.id,
        tenantId: user.tenantId
      }
    })

    if (!existingProduct) {
      return apiError('Product not found', 404)
    }

    await prisma.product.delete({
      where: { id: params.id }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'DELETE',
        resource: 'product',
        resourceId: params.id,
        details: JSON.stringify({ name: existingProduct.name })
      }
    })

    return apiResponse({ success: true })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}