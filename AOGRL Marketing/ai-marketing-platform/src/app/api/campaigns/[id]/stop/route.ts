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

    // Check if campaign can be stopped
    if (campaign.status === 'COMPLETED' || campaign.status === 'CANCELLED') {
      return apiError('Campaign is already stopped', 400)
    }

    // Update campaign status
    const updatedCampaign = await prisma.campaign.update({
      where: { id: campaignId },
      data: {
        status: 'COMPLETED',
        endDate: new Date()
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
        details: JSON.stringify({ action: 'stop', previousStatus: campaign.status })
      }
    })

    // Create scheduled job entry for stopping
    await prisma.scheduledJob.create({
      data: {
        jobId: `campaign-stop-${campaignId}-${Date.now()}`,
        type: 'CAMPAIGN_STOP',
        payload: JSON.stringify({ campaignId }),
        scheduledAt: new Date(),
        campaignId: campaignId,
        status: 'COMPLETED'
      }
    })

    return apiResponse({
      message: 'Campaign stopped successfully',
      campaign: {
        ...updatedCampaign,
        audience: JSON.parse(updatedCampaign.audience || '{}')
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}