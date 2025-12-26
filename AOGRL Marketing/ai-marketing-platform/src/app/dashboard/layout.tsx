'use client'

// Removed useSession import since we're removing authentication
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { Sidebar } from '@/components/sidebar'
import { Header } from '@/components/header'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Removed session check since we're removing authentication
  const router = useRouter()

  // Removed authentication check since we're removing authentication
  // useEffect and loading states are no longer needed

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-purple-50">
      <Sidebar />
      <div className="lg:pl-80">
        <Header />
        <main className="section-padding">
          <div className="container-app">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}