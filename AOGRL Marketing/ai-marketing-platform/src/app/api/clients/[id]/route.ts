import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await getAuthenticatedUser()
    const clientId = params.id

    const client = await prisma.client.findFirst({
      where: {
        id: clientId,
        tenantId: user.tenantId
      },
      include: {
        campaigns: {
          include: {
            analytics: {
              select: {
                impressions: true,
                clicks: true,
                conversions: true,
                spend: true,
                revenue: true
              }
            }
          }
        },
        _count: {
          select: {
            campaigns: true
          }
        }
      }
    })

    if (!client) {
      return apiError('Client not found', 404)
    }

    // Calculate client analytics
    const totalSpent = client.campaigns.reduce((sum, campaign) => {
      const campaignSpent = campaign.analytics.reduce((campaignSum, analytics) => 
        campaignSum + analytics.spend, 0)
      return sum + campaignSpent
    }, 0)

    const totalRevenue = client.campaigns.reduce((sum, campaign) => {
      const campaignRevenue = campaign.analytics.reduce((campaignSum, analytics) => 
        campaignSum + analytics.revenue, 0)
      return sum + campaignRevenue
    }, 0)

    const roi = totalSpent > 0 ? ((totalRevenue - totalSpent) / totalSpent) * 100 : 0

    const clientWithAnalytics = {
      ...client,
      analytics: {
        totalSpent,
        totalRevenue,
        roi,
        activeCampaigns: client.campaigns.filter(c => c.status === 'RUNNING').length,
        totalCampaigns: client.campaigns.length
      }
    }

    return apiResponse(clientWithAnalytics)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const clientId = params.id
    const body = await request.json()

    // Check if client exists and belongs to tenant
    const existingClient = await prisma.client.findFirst({
      where: {
        id: clientId,
        tenantId: user.tenantId
      }
    })

    if (!existingClient) {
      return apiError('Client not found', 404)
    }

    const { 
      name, 
      company, 
      email, 
      phone, 
      website, 
      industry, 
      contactPerson, 
      location, 
      totalBudget,
      currency,
      priority,
      status,
      notes 
    } = body

    // Check if email is being changed and if it conflicts with another client
    if (email && email !== existingClient.email) {
      const emailConflict = await prisma.client.findFirst({
        where: {
          email,
          tenantId: user.tenantId,
          id: { not: clientId }
        }
      })

      if (emailConflict) {
        return apiError('Another client with this email already exists')
      }
    }

    const updateData: any = {}
    if (name) updateData.name = name
    if (company) updateData.company = company
    if (email) updateData.email = email
    if (phone !== undefined) updateData.phone = phone
    if (website !== undefined) updateData.website = website
    if (industry !== undefined) updateData.industry = industry
    if (contactPerson !== undefined) updateData.contactPerson = contactPerson
    if (location !== undefined) updateData.location = location
    if (totalBudget !== undefined) updateData.totalBudget = parseFloat(totalBudget)
    if (currency) updateData.currency = currency
    if (priority) updateData.priority = priority
    if (status) updateData.status = status
    if (notes !== undefined) updateData.notes = notes

    const updatedClient = await prisma.client.update({
      where: { id: clientId },
      data: updateData,
      include: {
        _count: {
          select: {
            campaigns: true
          }
        }
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'UPDATE',
        resource: 'client',
        resourceId: clientId,
        details: JSON.stringify({ changes: Object.keys(updateData) })
      }
    })

    return apiResponse(updatedClient)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN])
    const clientId = params.id

    // Check if client exists and belongs to tenant
    const existingClient = await prisma.client.findFirst({
      where: {
        id: clientId,
        tenantId: user.tenantId
      },
      include: {
        _count: {
          select: {
            campaigns: true
          }
        }
      }
    })

    if (!existingClient) {
      return apiError('Client not found', 404)
    }

    // Check if client has active campaigns
    if (existingClient._count.campaigns > 0) {
      return apiError('Cannot delete client with existing campaigns. Please delete or reassign campaigns first.', 400)
    }

    await prisma.client.delete({
      where: { id: clientId }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'DELETE',
        resource: 'client',
        resourceId: clientId,
        details: JSON.stringify({ name: existingClient.name, company: existingClient.company })
      }
    })

    return apiResponse({ message: 'Client deleted successfully' })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}