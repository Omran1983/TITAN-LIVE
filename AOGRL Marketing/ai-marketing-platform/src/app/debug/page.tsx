'use client'

import { useState } from 'react'
// Removed useSession import since we're removing authentication

export default function DebugPage() {
  // Removed session-related code
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('TempPass123!')
  const [debugResult, setDebugResult] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const checkConfig = async () => {
    try {
      const response = await fetch('/api/debug/config')
      const data = await response.json()
      setDebugResult(data)
    } catch (error) {
      console.error('Error checking config:', error)
      setDebugResult({ error: 'Failed to check configuration' })
    }
  }

  const testAuth = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/debug/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      })
      const data = await response.json()
      setDebugResult(data)
    } catch (error) {
      console.error('Error testing auth:', error)
      setDebugResult({ error: 'Failed to test authentication' })
    } finally {
      setLoading(false)
    }
  }

  const seedDatabase = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/debug/seed', {
        method: 'POST',
      })
      const data = await response.json()
      setDebugResult(data)
    } catch (error) {
      console.error('Error seeding database:', error)
      setDebugResult({ error: 'Failed to seed database' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Authentication Debug</h1>
          <p className="text-gray-600">Check your authentication configuration and test login</p>
        </div>

        <div className="bg-white shadow rounded-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Session Status</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="font-medium text-gray-700">Status</h3>
              <p className="text-lg font-semibold mt-1">authenticated</p>
            </div>
            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="font-medium text-gray-700">Session</h3>
              <p className="text-lg font-semibold mt-1 truncate">
                Authenticated
              </p>
            </div>
          </div>
          
          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <h3 className="font-medium text-blue-800">Session Details</h3>
            <pre className="text-sm text-blue-900 mt-2 overflow-x-auto">
              {JSON.stringify({
                user: {
                  id: 'default',
                  email: 'user@example.com',
                  name: 'User',
                  role: 'ADMIN',
                  tenantId: 'default',
                  tenant: {
                    id: 'default',
                    name: 'Default Tenant',
                    isActive: true
                  }
                }
              }, null, 2)}
            </pre>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Configuration Check</h2>
          <button
            onClick={checkConfig}
            className="btn btn-primary mb-4"
          >
            Check Configuration
          </button>
          
          {debugResult && (
            <div className="mt-4 p-4 bg-gray-50 rounded-lg">
              <h3 className="font-medium text-gray-800">Results</h3>
              <pre className="text-sm text-gray-700 mt-2 overflow-x-auto">
                {JSON.stringify(debugResult, null, 2)}
              </pre>
            </div>
          )}
        </div>

        <div className="bg-white shadow rounded-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Authentication Test</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
          
          <div className="flex flex-wrap gap-3">
            <button
              onClick={testAuth}
              disabled={loading}
              className="btn btn-primary"
            >
              {loading ? 'Testing...' : 'Test Authentication'}
            </button>
            
            <button
              onClick={seedDatabase}
              disabled={loading}
              className="btn btn-secondary"
            >
              {loading ? 'Seeding...' : 'Seed Database'}
            </button>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Login Credentials</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="font-medium text-gray-700">Administrator</h3>
              <p className="mt-1">Email: <code className="bg-gray-100 px-1 rounded">admin@example.com</code></p>
              <p className="mt-1">Password: <code className="bg-gray-100 px-1 rounded">TempPass123!</code></p>
            </div>
            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="font-medium text-gray-700">Viewer</h3>
              <p className="mt-1">Email: <code className="bg-gray-100 px-1 rounded">viewer@example.com</code></p>
              <p className="mt-1">Password: <code className="bg-gray-100 px-1 rounded">TempPass123!</code></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}