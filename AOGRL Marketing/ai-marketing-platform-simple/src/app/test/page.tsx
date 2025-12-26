'use client'

import { useState } from 'react'

export default function TestPage() {
  const [imageUrl, setImageUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [prompt, setPrompt] = useState('A beautiful landscape with mountains and lake')

  const generateImage = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/generate-image', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prompt }),
      })
      
      const data = await response.json()
      console.log('API Response:', data)
      
      if (data.success) {
        setImageUrl(data.imageUrl)
      } else {
        // Even if not successful, we might still have a fallback image
        setImageUrl(data.imageUrl || '')
      }
    } catch (error) {
      console.error('Error:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Test Image Generation</h1>
        
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <div className="flex flex-col sm:flex-row gap-4 mb-4">
            <input
              type="text"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter your image prompt..."
            />
            <button
              onClick={generateImage}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {loading ? 'Generating...' : 'Generate Image'}
            </button>
          </div>
        </div>

        {imageUrl && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Generated Image</h2>
            <img 
              src={imageUrl} 
              alt="Generated content" 
              className="w-full max-w-2xl mx-auto rounded-lg shadow-md"
              onError={(e) => {
                console.log('Image failed to load')
                // Set a fallback image
                e.currentTarget.src = 'https://picsum.photos/600/400?random=1'
              }}
            />
          </div>
        )}
      </div>
    </div>
  )
}