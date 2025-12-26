'use client'

import { useState, useEffect } from 'react'

interface DashboardData {
  revenue: number;
  campaigns: number;
  impressions: number;
  clickRate: number;
  conversions: number;
  totalSpend: number;
  products: number;
  creatives: number;
  activeUsers: number;
  globalReach: number;
  aiInsights: number;
}

export default function TestDashboard() {
  const [data, setData] = useState<DashboardData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Fetch data from our API
    const fetchData = async () => {
      try {
        setLoading(true)
        
        const response = await fetch('/api/analytics/dashboard')
        if (!response.ok) {
          throw new Error('Failed to fetch data')
        }
        
        const result = await response.json()
        setData(result.data)
        setLoading(false)
      } catch (err) {
        setError('Failed to load data')
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-red-500 text-xl">{error}</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Test Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {data && Object.entries(data).map(([key, value]) => (
          <div key={key} className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-lg font-semibold text-gray-800 capitalize">{key.replace(/([A-Z])/g, ' $1').trim()}</h2>
            <p className="text-2xl font-bold text-indigo-600">{value}</p>
          </div>
        ))}
      </div>
    </div>
  )
}