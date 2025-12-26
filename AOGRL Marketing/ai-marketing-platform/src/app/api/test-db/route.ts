import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    console.log('Testing database connection...')
    
    // Test database connection by fetching creatives
    const creatives = await prisma.creative.findMany({
      take: 5,
      select: {
        id: true,
        type: true,
        content: true,
        prompt: true,
        status: true,
        createdAt: true,
      }
    })

    console.log('Database connection successful, found creatives:', creatives.length)
    
    return NextResponse.json({
      success: true,
      message: 'Database connection successful',
      creativesCount: creatives.length,
      sampleCreatives: creatives
    })
  } catch (error) {
    console.error('Database connection error:', error)
    return NextResponse.json({ 
      success: false, 
      error: 'Database connection failed',
      details: error.message 
    }, { status: 500 })
  }
}