import { NextAuthOptions } from 'next-auth'
import { PrismaAdapter } from '@next-auth/prisma-adapter'
import CredentialsProvider from 'next-auth/providers/credentials'
import { prisma } from '@/lib/prisma'

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        console.log('🔐 Auth attempt:', credentials?.email)
        
        if (!credentials?.email || !credentials?.password) {
          console.log('❌ Missing credentials')
          return null
        }

        // For demo purposes, we'll check against hardcoded values
        // This is a simplified approach for demonstration
        const validCredentials = 
          (credentials.email === 'admin@example.com' && credentials.password === 'TempPass123!') ||
          (credentials.email === 'viewer@example.com' && credentials.password === 'TempPass123!')

        if (!validCredentials) {
          console.log('❌ Invalid credentials for:', credentials.email)
          return null
        }

        // Find the user in the database
        const user = await prisma.user.findUnique({
          where: {
            email: credentials.email
          },
          include: {
            tenant: true
          }
        })

        if (!user || !user.isActive) {
          console.log('❌ User not found or inactive')
          return null
        }

        console.log('✅ Authentication successful for:', user.email)
        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          tenantId: user.tenantId,
          tenant: user.tenant
        }
      }
    })
  ],
  session: {
    strategy: 'jwt'
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role
        token.tenantId = user.tenantId
        token.tenant = user.tenant
      }
      return token
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token.sub!
        session.user.role = token.role as string
        session.user.tenantId = token.tenantId as string
        session.user.tenant = token.tenant as any
      }
      return session
    }
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error'
  }
}