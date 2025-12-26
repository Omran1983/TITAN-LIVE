import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth/next'
import { authOptions } from '@/lib/auth'
import { UserRole } from '@prisma/client'

export function apiResponse(data: any, status = 200) {
  return NextResponse.json(data, { status })
}

export function apiError(message: string, status = 400) {
  return NextResponse.json({ error: message }, { status })
}

export async function getAuthenticatedUser() {
  try {
    const session = await getServerSession(authOptions)
    if (!session?.user) {
      throw new Error('Unauthorized')
    }
    return session.user
  } catch (error) {
    // Return a more specific error that can be handled by API routes
    throw new Error('Unauthorized: ' + (error as Error).message)
  }
}

export async function requireRole(roles: UserRole[]) {
  try {
    const user = await getAuthenticatedUser()
    if (!roles.includes(user.role)) {
      throw new Error('Insufficient permissions')
    }
    return user
  } catch (error) {
    // Return a more specific error that can be handled by API routes
    throw new Error('Permission denied: ' + (error as Error).message)
  }
}