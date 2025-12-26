import { NextRequest } from 'next/server'
import { apiResponse, apiError, getAuthenticatedUser } from '@/lib/api-utils'
import { scraperService } from '@/lib/scrapers/scraper-service'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    
    const analytics = await scraperService.getScrapingAnalytics(user.tenantId)

    return apiResponse({
      analytics
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}