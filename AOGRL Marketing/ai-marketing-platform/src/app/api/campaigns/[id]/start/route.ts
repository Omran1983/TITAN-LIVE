import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const campaignId = params.id

    // Check if campaign exists and belongs to tenant
    const campaign = await prisma.campaign.findFirst({
      where: {
        id: campaignId,
        tenantId: user.tenantId
      }
    })

    if (!campaign) {
      return apiError('Campaign not found', 404)
    }

    // Check if campaign can be started
    if (campaign.status === 'RUNNING') {
      return apiError('Campaign is already running', 400)
    }

    if (campaign.status === 'COMPLETED' || campaign.status === 'CANCELLED') {
      return apiError('Cannot start a completed or cancelled campaign', 400)
    }

    // Update campaign status
    const updatedCampaign = await prisma.campaign.update({
      where: { id: campaignId },
      data: {
        status: 'RUNNING',
        startDate: campaign.startDate || new Date()
      },
      include: {
        createdBy: {
          select: { id: true, name: true, email: true }
        },
        creative: true,
        client: {
          select: { id: true, name: true, company: true }
        }
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'UPDATE',
        resource: 'campaign',
        resourceId: campaignId,
        details: JSON.stringify({ action: 'start', previousStatus: campaign.status })
      }
    })

    // TODO: In production, this would trigger actual campaign execution
    // For now, we'll create a scheduled job entry
    await prisma.scheduledJob.create({
      data: {
        jobId: `campaign-start-${campaignId}-${Date.now()}`,
        type: 'CAMPAIGN_START',
        payload: JSON.stringify({ campaignId }),
        scheduledAt: new Date(),
        campaignId: campaignId,
        status: 'COMPLETED'
      }
    })

    return apiResponse({
      message: 'Campaign started successfully',
      campaign: {
        ...updatedCampaign,
        audience: JSON.parse(updatedCampaign.audience || '{}')
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}