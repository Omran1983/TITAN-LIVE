import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError, getAuthenticatedUser } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()

    const userWithPreferences = await prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        name: true,
        email: true,
        preferredCurrency: true,
        preferredTimezone: true,
        preferredLanguage: true,
        tenant: {
          select: {
            defaultCurrency: true,
            defaultTimezone: true,
            defaultLanguage: true
          }
        }
      }
    })

    if (!userWithPreferences) {
      return apiError('User not found', 404)
    }

    return apiResponse({
      preferences: {
        currency: userWithPreferences.preferredCurrency,
        timezone: userWithPreferences.preferredTimezone,
        language: userWithPreferences.preferredLanguage
      },
      defaults: {
        currency: userWithPreferences.tenant.defaultCurrency,
        timezone: userWithPreferences.tenant.defaultTimezone,
        language: userWithPreferences.tenant.defaultLanguage
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}

export async function PUT(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser()
    const body = await request.json()
    
    const { currency, timezone, language } = body

    const updateData: any = {}
    if (currency) updateData.preferredCurrency = currency
    if (timezone) updateData.preferredTimezone = timezone
    if (language) updateData.preferredLanguage = language

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        preferredCurrency: true,
        preferredTimezone: true,
        preferredLanguage: true
      }
    })

    // Log audit
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        tenantId: user.tenantId,
        action: 'UPDATE',
        resource: 'user_preferences',
        resourceId: user.id,
        details: JSON.stringify({ changes: Object.keys(updateData) })
      }
    })

    return apiResponse({
      message: 'Preferences updated successfully',
      preferences: {
        currency: updatedUser.preferredCurrency,
        timezone: updatedUser.preferredTimezone,
        language: updatedUser.preferredLanguage
      }
    })
  } catch (error: any) {
    return apiError(error.message, error.message === 'Unauthorized' ? 401 : 500)
  }
}