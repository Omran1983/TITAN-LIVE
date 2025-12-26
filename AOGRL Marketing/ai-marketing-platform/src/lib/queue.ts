import { Queue, Worker, Job } from 'bullmq'
import { prisma } from '@/lib/prisma'
import { getAIProvider } from '@/lib/ai-providers'
import { JobType, JobStatus } from '@prisma/client'

const redisConnection = {
  host: process.env.UPSTASH_REDIS_URL?.split('@')[1]?.split(':')[0] || 'localhost',
  port: parseInt(process.env.UPSTASH_REDIS_URL?.split(':')[2] || '6379'),
  password: process.env.UPSTASH_REDIS_URL?.split('@')[0]?.split('//')[1]?.split(':')[1] || undefined,
  username: process.env.UPSTASH_REDIS_URL?.split('@')[0]?.split('//')[1]?.split(':')[0] || undefined,
  lazyConnect: true,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  enableReadyCheck: false,
  maxRetriesPerRequest: null,
}

// For demo purposes, use a simple in-memory queue if Redis is not available
const useInMemoryQueue = !process.env.UPSTASH_REDIS_URL || process.env.UPSTASH_REDIS_URL.includes('your-redis-url')

let campaignQueue: Queue | null = null
let worker: Worker | null = null

if (!useInMemoryQueue) {
  campaignQueue = new Queue('campaign-queue', {
    connection: redisConnection,
    defaultJobOptions: {
      removeOnComplete: 100,
      removeOnFail: 50,
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000,
      },
    },
  })

  worker = new Worker('campaign-queue', 
    async (job: Job) => {
      await processJob(job)
    },
    {
      connection: redisConnection,
      concurrency: 5,
    }
  )

  worker.on('completed', async (job) => {
    await updateJobStatus(job.id!, 'COMPLETED')
  })

  worker.on('failed', async (job, err) => {
    await updateJobStatus(job!.id!, 'FAILED', err.message)
  })
}

// In-memory queue for demo
const inMemoryJobs = new Map<string, any>()

async function processJob(job: Job) {
  const { type, payload } = job.data
  
  switch (type) {
    case 'CAMPAIGN_START':
      await handleCampaignStart(payload)
      break
    case 'CAMPAIGN_STOP':
      await handleCampaignStop(payload)
      break
    case 'CAMPAIGN_UPDATE':
      await handleCampaignUpdate(payload)
      break
    case 'CREATIVE_GENERATION':
      await handleCreativeGeneration(payload)
      break
    case 'ANALYTICS_SYNC':
      await handleAnalyticsSync(payload)
      break
    default:
      throw new Error(`Unknown job type: ${type}`)
  }
}

async function handleCampaignStart(payload: any) {
  const { campaignId } = payload
  
  await prisma.campaign.update({
    where: { id: campaignId },
    data: { status: 'RUNNING' }
  })
  
  // Generate initial analytics data
  const campaign = await prisma.campaign.findUnique({ where: { id: campaignId } })
  if (campaign) {
    const aiProvider = getAIProvider()
    const analytics = await aiProvider.generateAnalytics(campaignId, {
      start: new Date(),
      end: new Date(Date.now() + 24 * 60 * 60 * 1000) // Next 24 hours
    })
    
    for (const data of analytics) {
      await prisma.analytics.upsert({
        where: {
          campaignId_date: {
            campaignId,
            date: new Date()
          }
        },
        update: data,
        create: {
          campaignId,
          date: new Date(),
          ...data
        }
      })
    }
  }
}

async function handleCampaignStop(payload: any) {
  const { campaignId } = payload
  
  await prisma.campaign.update({
    where: { id: campaignId },
    data: { status: 'COMPLETED' }
  })
}

async function handleCampaignUpdate(payload: any) {
  const { campaignId, updates } = payload
  
  await prisma.campaign.update({
    where: { id: campaignId },
    data: updates
  })
}

async function handleCreativeGeneration(payload: any) {
  const { creativeId, prompt, type } = payload
  
  try {
    const aiProvider = getAIProvider()
    const result = await aiProvider.generateCreative({ type, prompt })
    
    await prisma.creative.update({
      where: { id: creativeId },
      data: {
        status: 'COMPLETED',
        content: JSON.stringify(result.content)
      }
    })
  } catch (error: any) {
    await prisma.creative.update({
      where: { id: creativeId },
      data: {
        status: 'FAILED',
        content: JSON.stringify({ error: error.message })
      }
    })
    throw error
  }
}

async function handleAnalyticsSync(payload: any) {
  const { campaignId, dateRange } = payload
  
  const aiProvider = getAIProvider()
  const analytics = await aiProvider.generateAnalytics(campaignId, dateRange)
  
  for (let i = 0; i < analytics.length; i++) {
    const date = new Date(dateRange.start)
    date.setDate(date.getDate() + i)
    
    await prisma.analytics.upsert({
      where: {
        campaignId_date: {
          campaignId,
          date
        }
      },
      update: analytics[i],
      create: {
        campaignId,
        date,
        ...analytics[i]
      }
    })
  }
}

async function updateJobStatus(jobId: string, status: JobStatus, error?: string) {
  await prisma.scheduledJob.update({
    where: { jobId },
    data: {
      status,
      processedAt: new Date(),
      error
    }
  })
}

export async function scheduleJob(
  type: JobType,
  payload: any,
  scheduledAt: Date = new Date(),
  campaignId?: string
) {
  let jobId: string
  
  if (useInMemoryQueue) {
    // Use in-memory queue for demo
    jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    
    const jobData = {
      id: jobId,
      type,
      payload,
      scheduledAt
    }
    
    inMemoryJobs.set(jobId, jobData)
    
    // Process immediately for demo (in real app, you'd use setTimeout)
    setTimeout(async () => {
      try {
        await updateJobStatus(jobId, 'PROCESSING')
        await processJob({ id: jobId, data: { type, payload } } as Job)
        await updateJobStatus(jobId, 'COMPLETED')
      } catch (error: any) {
        await updateJobStatus(jobId, 'FAILED', error.message)
      }
    }, 1000)
  } else {
    // Use Redis queue
    const delay = scheduledAt.getTime() - Date.now()
    const job = await campaignQueue!.add(
      type,
      { type, payload },
      { delay: Math.max(0, delay) }
    )
    jobId = job.id!
  }
  
  // Store job record in database
  await prisma.scheduledJob.create({
    data: {
      jobId,
      type,
      payload: JSON.stringify(payload),
      scheduledAt,
      campaignId,
      status: 'PENDING'
    }
  })
  
  return jobId
}

export async function getQueueStats() {
  if (useInMemoryQueue) {
    const jobs = await prisma.scheduledJob.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100
    })
    
    return {
      waiting: jobs.filter(j => j.status === 'PENDING').length,
      active: jobs.filter(j => j.status === 'PROCESSING').length,
      completed: jobs.filter(j => j.status === 'COMPLETED').length,
      failed: jobs.filter(j => j.status === 'FAILED').length,
      jobs: jobs.map(job => ({
        ...job,
        payload: JSON.parse(job.payload)
      }))
    }
  }
  
  if (!campaignQueue) {
    return { waiting: 0, active: 0, completed: 0, failed: 0, jobs: [] }
  }
  
  const stats = await campaignQueue.getWaiting()
  const active = await campaignQueue.getActive()
  const completed = await campaignQueue.getCompleted()
  const failed = await campaignQueue.getFailed()
  
  return {
    waiting: stats.length,
    active: active.length,
    completed: completed.length,
    failed: failed.length,
    jobs: [...stats, ...active, ...completed, ...failed].map(job => ({
      id: job.id,
      name: job.name,
      data: job.data,
      timestamp: job.timestamp,
      processedOn: job.processedOn,
      finishedOn: job.finishedOn,
      failedReason: job.failedReason
    }))
  }
}