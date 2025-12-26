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

    // Check if campaign can be paused
    if (campaign.status !== 'RUNNING') {
      return apiError('Only running campaigns can be paused', 400)
    }

    // Update campaign status
    const updatedCampaign = await prisma.campaign.update({
      where: { id: campaignId },
      data: {
        status: 'PAUSED'
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
        details: JSON.stringify({ action: 'pause', previousStatus: campaign.status })
      }
    })

    // Create scheduled job entry for pausing
    await prisma.scheduledJob.create({
      data: {
        jobId: `campaign-pause-${campaignId}-${Date.now()}`,
        type: 'CAMPAIGN_UPDATE',
        payload: JSON.stringify({ campaignId, action: 'pause' }),
        scheduledAt: new Date(),
        campaignId: campaignId,
        status: 'COMPLETED'
      }
    })

    return apiResponse({
      message: 'Campaign paused successfully',
      campaign: {
        ...updatedCampaign,
        audience: JSON.parse(updatedCampaign.audience || '{}')
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}