import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const status = searchParams.get('status')
    const search = searchParams.get('search') || ''

    const where: any = {
      tenantId: user.tenantId,
      ...(status && { status }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' as const } },
          { description: { contains: search, mode: 'insensitive' as const } }
        ]
      })
    }

    const [campaigns, total] = await Promise.all([
      prisma.campaign.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          createdBy: {
            select: { id: true, name: true, email: true }
          },
          creative: true,
          products: {
            include: {
              product: true
            }
          },
          _count: {
            select: {
              analytics: true,
              jobs: true
            }
          }
        }
      }),
      prisma.campaign.count({ where })
    ])

    // Parse audience JSON for each campaign
    const campaignsWithParsedData = campaigns.map(campaign => ({
      ...campaign,
      audience: JSON.parse(campaign.audience || '{}'),
      creative: campaign.creative ? {
        ...campaign.creative,
        content: JSON.parse(campaign.creative.content)
      } : null
    }))

    return apiResponse({
      campaigns: campaignsWithParsedData,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    const { name, description, budget, audience, productIds, creativeId, startDate, endDate } = body

    if (!name || !budget) {
      return apiError('Name and budget are required')
    }

    // Validate products belong to tenant
    if (productIds && productIds.length > 0) {
      const products = await prisma.product.findMany({
        where: {
          id: { in: productIds },
          tenantId: user.tenantId
        }
      })
      
      if (products.length !== productIds.length) {
        return apiError('One or more products not found')
      }
    }

    // Validate creative belongs to tenant
    if (creativeId) {
      const creative = await prisma.creative.findFirst({
        where: {
          id: creativeId,
          tenantId: user.tenantId
        }
      })
      
      if (!creative) {
        return apiError('Creative not found')
      }
    }

    const campaign = await prisma.campaign.create({
      data: {
        name,
        description,
        budget: parseFloat(budget),
        audience: JSON.stringify(audience || {}),
        createdById: user.id,
        tenantId: user.tenantId,
        creativeId,
        startDate: startDate ? new Date(startDate) : null,
        endDate: endDate ? new Date(endDate) : null
      },
      include: {
        createdBy: {
          select: { id: true, name: true, email: true }
        },
        creative: true
      }
    })

    // Link products to campaign
    if (productIds && productIds.length > 0) {
      await prisma.campaignProduct.createMany({
        data: productIds.map((productId: string) => ({
          campaignId: campaign.id,
          productId
        }))
      })
    }

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'CREATE',
        resource: 'campaign',
        resourceId: campaign.id,
        details: JSON.stringify({ name, budget, productCount: productIds?.length || 0 })
      }
    })

    return apiResponse({
      ...campaign,
      audience: JSON.parse(campaign.audience)
    }, 201)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}