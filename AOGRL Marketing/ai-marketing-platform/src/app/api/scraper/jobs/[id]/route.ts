import { NextRequest } from 'next/server'
import { apiResponse, apiError, requireRole } from '@/lib/api-utils'
import { scraperService } from '@/lib/scrapers/scraper-service'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const jobId = params.id

    const result = await scraperService.executeScraperJob(jobId)

    return apiResponse({
      message: 'Scraper job executed successfully',
      data: result
    })
  } catch (error: any) {
    return apiError(error.message, 500)
  }
}

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const jobId = params.id
    const body = await request.json()

    const updatedJob = await scraperService.updateScraperJob(jobId, body)

    return apiResponse({
      message: 'Scraper job updated successfully',
      job: updatedJob
    })
  } catch (error: any) {
    return apiError(error.message, 500)
  }
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    await requireRole([UserRole.ADMIN])
    const jobId = params.id

    await scraperService.deleteScraperJob(jobId)

    return apiResponse({
      message: 'Scraper job deleted successfully'
    })
  } catch (error: any) {
    return apiError(error.message, 500)
  }
}