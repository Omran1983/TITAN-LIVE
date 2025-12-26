import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'
import { queueManager } from '@/lib/enhanced-queue-manager'

export async function GET(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR, UserRole.VIEWER])
    
    const { searchParams } = new URL(request.url)
    const action = searchParams.get('action')
    
    switch (action) {
      case 'stats':
        const stats = await queueManager.getQueueStats()
        return apiResponse({ stats })
        
      case 'metrics':
        const timeframe = searchParams.get('timeframe') as '1h' | '24h' | '7d' | '30d' || '24h'
        const metrics = await queueManager.getJobMetrics(timeframe)
        return apiResponse({ metrics, timeframe })
        
      case 'workers':
        const workerStats = await queueManager.getWorkerStats()
        return apiResponse({ workers: workerStats })
        
      default:
        // Get jobs with filters
        const statusFilter = searchParams.get('status')?.split(',') as any[]
        const typeFilter = searchParams.get('type')?.split(',') as any[]
        const limit = parseInt(searchParams.get('limit') || '50')
        const offset = parseInt(searchParams.get('offset') || '0')
        
        const jobs = await queueManager.getJobs({
          status: statusFilter,
          type: typeFilter,
          limit,
          offset
        })
        
        return apiResponse(jobs)
    }
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { action, ...data } = body
    
    switch (action) {
      case 'create':
        const job = await queueManager.createJob(data, user.tenantId)
        return apiResponse({ job, message: 'Job created successfully' })
        
      case 'bulk_pause':
        const pauseResult = await queueManager.bulkPauseJobs(data.jobIds)
        return apiResponse({ result: pauseResult, message: 'Bulk pause operation completed' })
        
      case 'bulk_retry':
        const retryResult = await queueManager.bulkRetryJobs(data.jobIds)
        return apiResponse({ result: retryResult, message: 'Bulk retry operation completed' })
        
      case 'create_template':
        const templateId = await queueManager.createJobTemplate(data)
        return apiResponse({ templateId, message: 'Job template created successfully' })
        
      default:
        return apiError('Invalid action specified')
    }
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}