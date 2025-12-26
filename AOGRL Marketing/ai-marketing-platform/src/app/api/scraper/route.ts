import { NextRequest } from 'next/server'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { scraperService, ScraperType } from '@/lib/scrapers/scraper-service'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const { searchParams } = new URL(request.url)
    
    const type = searchParams.get('type') as ScraperType
    const limit = parseInt(searchParams.get('limit') || '50')

    const data = await scraperService.getScrapedData(user.tenantId, type, limit)

    return apiResponse({
      data,
      total: data.length
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { url, type } = body

    if (!url || !type) {
      return apiError('URL and type are required')
    }

    // Perform manual scrape
    const result = await scraperService.performManualScrape(url, type, user.tenantId)

    return apiResponse({
      message: 'Scraping completed successfully',
      data: result
    }, 201)
  } catch (error: any) {
    return apiError(error.message, 500)
  }
}