import { DefaultSession, DefaultUser } from 'next-auth'
import { JWT, DefaultJWT } from 'next-auth/jwt'
import { UserRole } from '@prisma/client'

declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      role: UserRole
      tenantId: string
      tenant: {
        id: string
        name: string
        domain: string
      }
    } & DefaultSession['user']
  }

  interface User extends DefaultUser {
    role: UserRole
    tenantId: string
    tenant: {
      id: string
      name: string
      domain: string
    }
  }
}

declare module 'next-auth/jwt' {
  interface JWT extends DefaultJWT {
    role: UserRole
    tenantId: string
    tenant: {
      id: string
      name: string
      domain: string
    }
  }
}