'use client'

import { useState, useEffect } from 'react'

export default function SimpleContentManager() {
  const [creatives, setCreatives] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchCreatives = async () => {
      try {
        setLoading(true)
        setError(null)
        
        const response = await fetch('/api/creatives')
        const data = await response.json()
        
        if (response.ok) {
          setCreatives(data.creatives || [])
        } else {
          // Only set error if it's meaningful
          const errorMessage = data.error || 'Failed to load creatives'
          if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
            setError(errorMessage)
          } else {
            // Set a generic error message for UI
            setError('Failed to load creatives')
          }
        }
      } catch (err) {
        // Only log and set error if it's meaningful
        const errorMessage = `Error: ${(err as Error).message}`
        if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
          console.error('Creatives fetch error:', errorMessage)
          setError(errorMessage)
        } else {
          // Set a generic error message for UI
          setError('Failed to load creatives')
        }
      } finally {
        setLoading(false)
      }
    }

    fetchCreatives()
  }, [])

  // Simple function to get image URL from content
  const getImageUrl = (content: any): string | null => {
    if (!content) return null
    
    // Direct imageUrl property (from seed data)
    if (content.imageUrl) {
      console.log('Found direct imageUrl:', content.imageUrl)
      return content.imageUrl
    }
    
    // Nested in result object (from AI generation)
    if (content.result?.url) {
      console.log('Found result.url:', content.result.url)
      return content.result.url
    }
    
    return null
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
        <strong>Error:</strong> {error}
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="p-6 border-b border-gray-200">
        <h2 className="text-xl font-semibold">AI Generated Content</h2>
        <p className="text-gray-600">Found {creatives.length} items</p>
      </div>
      
      <div className="p-6">
        {creatives.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">No content found</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {creatives.map((creative) => {
              const imageUrl = getImageUrl(creative.content)
              const isDataUrl = imageUrl && imageUrl.startsWith('data:')
              const isPlaceholder = isDataUrl && imageUrl.includes('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==')
              
              return (
                <div key={creative.id} className="border border-gray-200 rounded-lg overflow-hidden">
                  <div className="p-4 bg-gray-50 border-b">
                    <div className="flex justify-between items-start">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {creative.type}
                      </span>
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        {creative.status}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-2">
                      {new Date(creative.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  
                  <div className="p-4">
                    {creative.type === 'IMAGE' && imageUrl ? (
                      <div>
                        {isPlaceholder ? (
                          <div className="bg-yellow-100 border border-yellow-300 rounded h-48 flex flex-col items-center justify-center text-center p-4">
                            <div className="text-yellow-800 font-bold mb-2">Placeholder Image</div>
                            <div className="text-yellow-700 text-sm">1x1 pixel (invisible)</div>
                            <div className="text-yellow-600 text-xs mt-1">AI generation placeholder</div>
                          </div>
                        ) : (
                          <img 
                            src={imageUrl} 
                            alt="AI Generated" 
                            className="w-full h-48 object-cover rounded"
                            onError={(e) => {
                              console.log('Image load error for URL:', imageUrl)
                            }}
                          />
                        )}
                        <div className="text-xs text-gray-500 mt-2">
                          {isDataUrl ? (
                            isPlaceholder ? 'Placeholder Data URL' : 'Data URL'
                          ) : (
                            'Regular URL'
                          )}
                        </div>
                      </div>
                    ) : creative.type === 'COPY' ? (
                      <p className="text-sm text-gray-700 mb-3 line-clamp-3">
                        {typeof creative.content === 'string' 
                          ? creative.content 
                          : creative.content?.text || creative.content?.description || 'Copy content'}
                      </p>
                    ) : (
                      <p className="text-sm text-gray-500 mb-3">
                        {creative.type} content
                      </p>
                    )}
                    
                    {creative.prompt && (
                      <p className="text-xs text-gray-500 line-clamp-2">
                        Prompt: {creative.prompt}
                      </p>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}