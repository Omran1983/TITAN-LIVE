import { NextRequest } from 'next/server'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { scraperService } from '@/lib/scrapers/scraper-service'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    
    const jobs = await scraperService.getScraperJobs(user.tenantId)

    return apiResponse({
      jobs
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { name, type, url, frequency, config } = body

    if (!name || !type || !url || !frequency) {
      return apiError('Name, type, URL, and frequency are required')
    }

    const job = await scraperService.createScraperJob({
      name,
      type,
      url,
      frequency,
      config,
      tenantId: user.tenantId
    })

    return apiResponse({
      message: 'Scraper job created successfully',
      job
    }, 201)
  } catch (error: any) {
    return apiError(error.message, 500)
  }
}