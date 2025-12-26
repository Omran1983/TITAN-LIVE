import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser, requireRole } from '@/lib/api-utils'
import { UserRole } from '@prisma/client'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const status = searchParams.get('status')
    const search = searchParams.get('search') || ''

    const where: any = {
      tenantId: user.tenantId,
      ...(status && { status }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' as const } },
          { company: { contains: search, mode: 'insensitive' as const } },
          { email: { contains: search, mode: 'insensitive' as const } }
        ]
      })
    }

    const [clients, total] = await Promise.all([
      prisma.client.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          campaigns: {
            select: {
              id: true,
              name: true,
              status: true,
              budget: true,
              currency: true
            }
          },
          _count: {
            select: {
              campaigns: true
            }
          }
        }
      }),
      prisma.client.count({ where })
    ])

    return apiResponse({
      clients,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireRole([UserRole.ADMIN, UserRole.EDITOR])
    const body = await request.json()
    
    const { 
      name, 
      company, 
      email, 
      phone, 
      website, 
      industry, 
      contactPerson, 
      location, 
      totalBudget,
      currency,
      priority,
      notes 
    } = body

    if (!name || !company || !email) {
      return apiError('Name, company, and email are required')
    }

    // Check if client with this email already exists for this tenant
    const existingClient = await prisma.client.findFirst({
      where: {
        email,
        tenantId: user.tenantId
      }
    })

    if (existingClient) {
      return apiError('Client with this email already exists')
    }

    const client = await prisma.client.create({
      data: {
        name,
        company,
        email,
        phone: phone || '',
        website: website || '',
        industry: industry || '',
        contactPerson: contactPerson || '',
        location: location || '',
        totalBudget: totalBudget ? parseFloat(totalBudget) : 0,
        currency: currency || 'USD',
        priority: priority || 'medium',
        notes: notes || '',
        tenantId: user.tenantId,
        status: 'active'
      },
      include: {
        _count: {
          select: {
            campaigns: true
          }
        }
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'CREATE',
        resource: 'client',
        resourceId: client.id,
        details: JSON.stringify({ name, company, email })
      }
    })

    return apiResponse(client, 201)
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}