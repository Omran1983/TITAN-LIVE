'use client'

import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { PencilIcon, TrashIcon } from '@heroicons/react/24/outline'

interface CreativeContent {
  id: string
  type: string
  content: any
  prompt: string | null
  status: string
  createdAt: string
}

export default function ContentManager() {
  const [creatives, setCreatives] = useState<CreativeContent[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCreative, setSelectedCreative] = useState<CreativeContent | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [editContent, setEditContent] = useState<any>({})

  useEffect(() => {
    fetchCreatives()
  }, [])

  const fetchCreatives = async () => {
    try {
      setLoading(true)
      const response = await fetch('/api/creatives')
      const data = await response.json()
      
      if (response.ok) {
        setCreatives(data.creatives)
      } else {
        toast.error(data.error || 'Failed to fetch creatives')
      }
    } catch (error) {
      toast.error('Failed to fetch creatives')
    } finally {
      setLoading(false)
    }
  }

  const handleEdit = (creative: CreativeContent) => {
    setSelectedCreative(creative)
    setEditContent(creative.content)
    setIsEditing(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this creative content?')) {
      return
    }

    try {
      const response = await fetch(`/api/creatives/${id}`, {
        method: 'DELETE',
      })

      const data = await response.json()

      if (response.ok) {
        toast.success('Creative deleted successfully')
        fetchCreatives() // Refresh the list
      } else {
        toast.error(data.error || 'Failed to delete creative')
      }
    } catch (error) {
      toast.error('Failed to delete creative')
    }
  }

  const handleSave = async () => {
    if (!selectedCreative) return

    try {
      const response = await fetch(`/api/creatives/${selectedCreative.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: editContent,
        }),
      })

      const data = await response.json()

      if (response.ok) {
        toast.success('Creative updated successfully')
        setIsEditing(false)
        setSelectedCreative(null)
        fetchCreatives() // Refresh the list
      } else {
        toast.error(data.error || 'Failed to update creative')
      }
    } catch (error) {
      toast.error('Failed to update creative')
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  // Simple function to get image URL from content
  const getImageUrl = (content: any): string | null => {
    if (!content) return null
    
    // Direct imageUrl property (from seed data)
    if (content.imageUrl) {
      return content.imageUrl
    }
    
    // Nested in result object (from AI generation)
    if (content.result?.url) {
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

  return (
    <div className="space-y-6">
      <div className="surface-elevated">
        <div className="p-6 border-b border-gray-100">
          <h2 className="text-headline">AI Generated Content</h2>
          <p className="text-body mt-1">Manage all your AI-generated images, videos, and copy</p>
        </div>
        
        <div className="p-6">
          {creatives.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-body">No AI-generated content found.</p>
              <p className="text-caption mt-2">Create some content using the generation tools.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {creatives.map((creative) => {
                const imageUrl = getImageUrl(creative.content)
                const isDataUrl = imageUrl && imageUrl.startsWith('data:')
                const isPlaceholder = isDataUrl && imageUrl.includes('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==')
                
                return (
                  <div key={creative.id} className="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow">
                    <div className="p-4 border-b border-gray-100">
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium status-badge bg-blue-100 text-blue-800">
                            {creative.type}
                          </span>
                          <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium status-badge bg-green-100 text-green-800">
                            {creative.status}
                          </span>
                        </div>
                        <div className="flex space-x-2">
                          <button
                            onClick={() => handleEdit(creative)}
                            className="text-gray-500 hover:text-blue-600"
                          >
                            <PencilIcon className="h-5 w-5" />
                          </button>
                          <button
                            onClick={() => handleDelete(creative.id)}
                            className="text-gray-500 hover:text-red-600"
                          >
                            <TrashIcon className="h-5 w-5" />
                          </button>
                        </div>
                      </div>
                      <p className="text-sm text-gray-500 mt-2">
                        {formatDate(creative.createdAt)}
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
                              <div className="mt-2 text-xs text-yellow-700 bg-yellow-200 px-2 py-1 rounded">
                                This is a placeholder indicating AI generation is complete
                              </div>
                            </div>
                          ) : (
                            <img 
                              src={imageUrl} 
                              alt="AI Generated" 
                              className="w-full h-48 object-cover rounded"
                              onError={(e) => {
                                // Handle broken images by showing a fallback
                                const target = e.target as HTMLImageElement;
                                target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPkltYWdlIE5vdCBGb3VuZDwvdGV4dD48L3N2Zz4=';
                              }}
                            />
                          )}
                        </div>
                      ) : creative.type === 'COPY' && (typeof creative.content === 'string' ? creative.content : creative.content?.text || creative.content?.description) ? (
                        <p className="text-body line-clamp-3">
                          {typeof creative.content === 'string'
                            ? creative.content
                            : creative.content.text || creative.content.description}
                        </p>
                      ) : creative.type === 'VIDEO' ? (
                        <div className="bg-gray-100 rounded h-48 flex items-center justify-center">
                          <span className="text-gray-500">Video Content</span>
                        </div>
                      ) : (
                        <p className="text-caption text-gray-500">
                          {creative.prompt || 'No preview available'}
                        </p>
                      )}

                      {creative.prompt && (
                        <p className="text-caption text-gray-500 mt-3 line-clamp-2">
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

      {/* Edit Modal */}
      {isEditing && selectedCreative && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="surface-elevated max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-100">
              <h3 className="text-headline">Edit Creative Content</h3>
              <p className="text-body mt-1">Type: {selectedCreative.type}</p>
            </div>
            
            <div className="p-6 space-y-6">
              <div>
                <label className="form-label">Content</label>
                <textarea
                  className="form-input w-full h-40"
                  value={JSON.stringify(editContent, null, 2)}
                  onChange={(e) => setEditContent(JSON.parse(e.target.value))}
                />
              </div>
              
              {selectedCreative.prompt && (
                <div>
                  <label className="form-label">Original Prompt</label>
                  <p className="form-input w-full">{selectedCreative.prompt}</p>
                </div>
              )}
              
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setIsEditing(false)
                    setSelectedCreative(null)
                  }}
                  className="btn btn-secondary"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  className="btn btn-primary"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}