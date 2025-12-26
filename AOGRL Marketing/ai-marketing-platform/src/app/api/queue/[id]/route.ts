import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { queueManager } from '@/lib/enhanced-queue-manager'

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    const jobId = params.id

    const jobDetails = await queueManager.getJobDetails(jobId)
    
    if (!jobDetails) {
      return apiError('Job not found', 404)
    }

    return apiResponse({
      job: jobDetails,
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const jobId = params.id
    const body = await request.json()
    
    const { action } = body

    let result
    let message

    switch (action) {
      case 'pause':
        await queueManager.pauseJob(jobId)
        message = 'Job paused successfully'
        break
        
      case 'resume':
        await queueManager.resumeJob(jobId)
        message = 'Job resumed successfully'
        break
        
      case 'cancel':
        await queueManager.cancelJob(jobId)
        message = 'Job cancelled successfully'
        break
        
      case 'retry':
        await queueManager.retryJob(jobId)
        message = 'Job retry initiated'
        break
        
      default:
        return apiError('Invalid action specified')
    }

    return apiResponse({ message, timestamp: new Date().toISOString() })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const user = await requireRole([UserRole.ADMIN])
    const jobId = params.id

    await queueManager.deleteJob(jobId)

    return apiResponse({
      message: 'Job deleted successfully',
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}