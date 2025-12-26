import { prisma } from '@/lib/prisma'
import { CompetitorScraper } from './competitor-scraper'
import { SocialMediaScraper } from './social-media-scraper'
import { MarketIntelligenceScraper } from './market-intelligence-scraper'
import { BaseScraper, ScrapedData } from './base-scraper'

// Define enums locally until Prisma client updates
export enum ScraperType {
  COMPETITOR_PRICING = 'COMPETITOR_PRICING',
  COMPETITOR_PRODUCTS = 'COMPETITOR_PRODUCTS',
  SOCIAL_MEDIA_METRICS = 'SOCIAL_MEDIA_METRICS',
  MARKET_TRENDS = 'MARKET_TRENDS',
  AD_CREATIVE = 'AD_CREATIVE',
  SEO_KEYWORDS = 'SEO_KEYWORDS',
  NEWS_SENTIMENT = 'NEWS_SENTIMENT',
  INDUSTRY_REPORTS = 'INDUSTRY_REPORTS'
}

export enum ScraperJobStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  DISABLED = 'DISABLED',
  ERROR = 'ERROR'
}

export interface ScraperJobConfig {
  name: string
  type: ScraperType
  url: string
  frequency: string // Cron expression - Vercel Hobby plan only supports daily jobs
  config?: any
  tenantId: string
}

export class ScraperService {
  private scrapers: Map<ScraperType, BaseScraper>

  constructor() {
    this.scrapers = new Map<ScraperType, BaseScraper>([
      [ScraperType.COMPETITOR_PRICING, new CompetitorScraper()],
      [ScraperType.COMPETITOR_PRODUCTS, new CompetitorScraper()],
      [ScraperType.SOCIAL_MEDIA_METRICS, new SocialMediaScraper()],
      [ScraperType.MARKET_TRENDS, new MarketIntelligenceScraper()],
      [ScraperType.NEWS_SENTIMENT, new MarketIntelligenceScraper()],
      [ScraperType.INDUSTRY_REPORTS, new MarketIntelligenceScraper()],
    ])
  }

  // Create a new scraper job
  async createScraperJob(config: ScraperJobConfig) {
    try {
      // Validate URL
      new URL(config.url)
      
      // Ensure frequency complies with Vercel Hobby plan limitations
      // Only allow daily or less frequent cron expressions
      const allowedFrequencies = [
        '0 0 * * *',     // Daily at midnight
        '0 0 * * 0',     // Weekly on Sunday
        '0 0 1 * *',     // Monthly on 1st
        '0 0 1 1 *'      // Yearly on Jan 1st
      ]
      
      if (!allowedFrequencies.includes(config.frequency)) {
        // Default to daily if not allowed
        config.frequency = '0 0 * * *'
      }
      
      const job = await prisma.scraperJob.create({
        data: {
          name: config.name,
          type: config.type,
          url: config.url,
          frequency: config.frequency,
          config: JSON.stringify(config.config || {}),
          tenantId: config.tenantId,
          nextRun: this.calculateNextRun(config.frequency)
        }
      })

      return job
    } catch (error: any) {
      throw new Error(`Failed to create scraper job: ${error.message}`)
    }
  }

  // Execute a scraper job
  async executeScraperJob(jobId: string): Promise<ScrapedData> {
    const job = await prisma.scraperJob.findUnique({
      where: { id: jobId }
    })

    if (!job) {
      throw new Error('Scraper job not found')
    }

    if (job.status !== ScraperJobStatus.ACTIVE) {
      throw new Error('Scraper job is not active')
    }

    const scraper = this.scrapers.get(job.type)
    if (!scraper) {
      throw new Error(`No scraper available for type: ${job.type}`)
    }

    try {
      // Execute the scraping
      const scrapedData = await scraper.scrape(job.url)

      // Store the scraped data
      await prisma.scraperData.create({
        data: {
          jobId: job.id,
          type: job.type,
          url: job.url,
          title: scrapedData.title,
          content: JSON.stringify(scrapedData.content),
          metadata: JSON.stringify(scrapedData.metadata),
          hash: scrapedData.hash,
          tenantId: job.tenantId
        }
      })

      // Update job last run time and next run
      await prisma.scraperJob.update({
        where: { id: job.id },
        data: {
          lastRun: new Date(),
          nextRun: this.calculateNextRun(job.frequency),
          status: ScraperJobStatus.ACTIVE
        }
      })

      return scrapedData
    } catch (error: any) {
      // Update job with error status
      await prisma.scraperJob.update({
        where: { id: job.id },
        data: {
          status: ScraperJobStatus.ERROR,
          lastRun: new Date()
        }
      })

      throw new Error(`Scraping failed: ${error.message}`)
    }
  }

  // Get scraped data for a tenant
  async getScrapedData(tenantId: string, type?: ScraperType, limit: number = 50) {
    const where: any = { tenantId }
    if (type) where.type = type

    const data = await prisma.scraperData.findMany({
      where,
      orderBy: { scrapedAt: 'desc' },
      take: limit,
      include: {
        job: {
          select: {
            name: true,
            type: true,
            frequency: true
          }
        }
      }
    })

    return data.map((item: any) => ({
      ...item,
      content: JSON.parse(item.content),
      metadata: item.metadata ? JSON.parse(item.metadata) : null
    }))
  }

  // Get scraper jobs for a tenant
  async getScraperJobs(tenantId: string) {
    return prisma.scraperJob.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: {
            data: true
          }
        }
      }
    })
  }

  // Update scraper job
  async updateScraperJob(jobId: string, updates: Partial<ScraperJobConfig & { status: ScraperJobStatus }>) {
    const updateData: any = {}
    
    if (updates.name) updateData.name = updates.name
    if (updates.url) updateData.url = updates.url
    if (updates.frequency) {
      // Ensure frequency complies with Vercel Hobby plan limitations
      const allowedFrequencies = [
        '0 0 * * *',     // Daily at midnight
        '0 0 * * 0',     // Weekly on Sunday
        '0 0 1 * *',     // Monthly on 1st
        '0 0 1 1 *'      // Yearly on Jan 1st
      ]
      
      // Default to daily if not allowed
      updateData.frequency = allowedFrequencies.includes(updates.frequency) 
        ? updates.frequency 
        : '0 0 * * *'
      updateData.nextRun = this.calculateNextRun(updateData.frequency)
    }
    if (updates.config) updateData.config = JSON.stringify(updates.config)
    if (updates.status) updateData.status = updates.status

    return prisma.scraperJob.update({
      where: { id: jobId },
      data: updateData
    })
  }

  // Delete scraper job and associated data
  async deleteScraperJob(jobId: string) {
    // Delete associated data first
    await prisma.scraperData.deleteMany({
      where: { jobId }
    })

    // Delete the job
    await prisma.scraperJob.delete({
      where: { id: jobId }
    })
  }

  // Manual scrape without creating a job
  async performManualScrape(url: string, type: ScraperType, tenantId: string): Promise<ScrapedData> {
    const scraper = this.scrapers.get(type)
    if (!scraper) {
      throw new Error(`No scraper available for type: ${type}`)
    }

    try {
      // Validate URL
      new URL(url)
      
      const scrapedData = await scraper.scrape(url)

      // Store the scraped data with a temporary job record
      const tempJob = await prisma.scraperJob.create({
        data: {
          name: `Manual Scrape - ${new Date().toISOString()}`,
          type,
          url,
          frequency: '0 0 1 1 *', // Yearly - never runs automatically
          config: '{}',
          status: ScraperJobStatus.DISABLED,
          tenantId
        }
      })

      await prisma.scraperData.create({
        data: {
          jobId: tempJob.id,
          type,
          url,
          title: scrapedData.title,
          content: JSON.stringify(scrapedData.content),
          metadata: JSON.stringify(scrapedData.metadata),
          hash: scrapedData.hash,
          tenantId
        }
      })

      return scrapedData
    } catch (error: any) {
      throw new Error(`Manual scraping failed: ${error.message}`)
    }
  }

  // Calculate next run time based on cron expression
  private calculateNextRun(cronExpression: string): Date {
    // Simple cron parser for common patterns
    // In production, use a proper cron library like 'node-cron'
    const now = new Date()
    
    if (cronExpression === '0 0 * * *') { // Daily
      return new Date(now.getTime() + 24 * 60 * 60 * 1000)
    } else if (cronExpression === '0 0 * * 0') { // Weekly
      return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
    } else if (cronExpression === '0 0 1 * *') { // Monthly
      const nextMonth = new Date(now)
      nextMonth.setMonth(nextMonth.getMonth() + 1)
      nextMonth.setDate(1)
      return nextMonth
    } else if (cronExpression === '0 0 1 1 *') { // Yearly
      const nextYear = new Date(now)
      nextYear.setFullYear(nextYear.getFullYear() + 1)
      nextYear.setMonth(0) // January
      nextYear.setDate(1)
      return nextYear
    } else {
      // Default to daily
      return new Date(now.getTime() + 24 * 60 * 60 * 1000)
    }
  }

  // Get analytics for scraped data
  async getScrapingAnalytics(tenantId: string) {
    const [totalData, jobStats, recentData] = await Promise.all([
      prisma.scraperData.count({ where: { tenantId } }),
      prisma.scraperJob.groupBy({
        by: ['type', 'status'],
        where: { tenantId },
        _count: { id: true }
      }),
      prisma.scraperData.findMany({
        where: { tenantId },
        orderBy: { scrapedAt: 'desc' },
        take: 10,
        select: {
          type: true,
          scrapedAt: true,
          metadata: true
        }
      })
    ])

    const typeDistribution = jobStats.reduce((acc: Record<string, number>, stat: any) => {
      acc[stat.type] = (acc[stat.type] || 0) + stat._count.id
      return acc
    }, {} as Record<string, number>)

    const statusDistribution = jobStats.reduce((acc: Record<string, number>, stat: any) => {
      acc[stat.status] = (acc[stat.status] || 0) + stat._count.id
      return acc
    }, {} as Record<string, number>)

    return {
      totalDataPoints: totalData,
      typeDistribution,
      statusDistribution,
      recentActivity: recentData
    }
  }
}

// Export singleton instance
export const scraperService = new ScraperService()