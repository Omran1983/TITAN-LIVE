'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function SignIn() {
  const router = useRouter()

  // Redirect to dashboard immediately since we're removing authentication
  useEffect(() => {
    router.push('/dashboard')
  }, [router])

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      {/* Redirecting to dashboard */}
      <div className="text-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600 mx-auto"></div>
        <h2 className="mt-4 text-xl font-semibold">Redirecting to Dashboard...</h2>
        <p className="mt-2 text-gray-600">Authentication has been removed. Redirecting you to the dashboard.</p>
      </div>
    </div>
  )
}
