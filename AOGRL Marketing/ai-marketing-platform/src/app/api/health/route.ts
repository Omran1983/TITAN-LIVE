import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`
    
    // Get basic counts
    const [userCount, productCount, campaignCount] = await Promise.all([
      prisma.user.count(),
      prisma.product.count(), 
      prisma.campaign.count()
    ])
    
    return NextResponse.json({ 
      ok: true,
      database: 'connected',
      stats: {
        users: userCount,
        products: productCount,
        campaigns: campaignCount
      },
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    console.error('Health check failed:', error)
    return NextResponse.json({ 
      ok: false, 
      database: 'disconnected',
      error: error.message 
    }, { status: 500 })
  }
}