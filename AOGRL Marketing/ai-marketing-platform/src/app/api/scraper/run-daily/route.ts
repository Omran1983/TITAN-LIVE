import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'
import { scraperService } from '@/lib/scrapers/scraper-service'

// This endpoint is for Vercel cron jobs - runs daily scraper jobs
export async function GET(request: NextRequest) {
  try {
    // Verify this is a cron request (Vercel sets this header)
    const isCronRequest = request.headers.get('x-vercel-cron') === '1'
    if (!isCronRequest) {
      return apiError('This endpoint is only accessible via Vercel cron jobs', 403)
    }
    
    console.log('🕷️ Starting daily scraper jobs...')
    
    // Get all active scraper jobs that should run today
    const today = new Date()
    const jobs = await prisma.scraperJob.findMany({
      where: {
        status: 'ACTIVE',
        nextRun: {
          lte: today
        }
      }
    })
    
    console.log(`📋 Found ${jobs.length} scraper jobs to run`)
    
    let completedCount = 0
    let failedCount = 0
    
    // Execute each job
    for (const job of jobs) {
      try {
        console.log(`🚀 Executing scraper job: ${job.name}`)
        await scraperService.executeScraperJob(job.id)
        completedCount++
        console.log(`✅ Completed scraper job: ${job.name}`)
      } catch (error) {
        console.error(`❌ Failed to execute scraper job ${job.name}:`, error)
        failedCount++
        
        // Update job status to error
        await prisma.scraperJob.update({
          where: { id: job.id },
          data: {
            status: 'ERROR',
            lastRun: new Date()
          }
        })
      }
    }
    
    return apiResponse({
      message: 'Daily scraper jobs completed',
      jobsCompleted: completedCount,
      jobsFailed: failedCount,
      totalJobs: jobs.length
    })
  } catch (error: any) {
    console.error('Daily scraper jobs failed:', error)
    return apiError(`Daily scraper jobs failed: ${error.message}`, 500)
  }
}