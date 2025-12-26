'use client'

import { useState } from 'react'
import { PhotoIcon, PencilIcon, TrashIcon, PlusIcon } from '@heroicons/react/24/outline'

export default function CreativePage() {
  const [creatives, setCreatives] = useState([
    {
      id: '1',
      type: 'IMAGE',
      content: {
        imageUrl: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=400&h=300&fit=crop',
        title: 'Experience Pure Sound',
        description: 'Discover the ultimate audio experience with our premium wireless headphones.'
      },
      prompt: 'Create an engaging ad for premium wireless headphones',
      status: 'COMPLETED',
      createdAt: new Date().toISOString()
    },
    {
      id: '2',
      type: 'COPY',
      content: {
        title: 'Track Your Progress',
        description: 'Monitor your health and fitness goals with precision tracking technology.'
      },
      prompt: 'Write compelling copy for fitness tracker campaign',
      status: 'COMPLETED',
      createdAt: new Date(Date.now() - 86400000).toISOString()
    },
    {
      id: '3',
      type: 'IMAGE',
      content: {
        imageUrl: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=400&h=300&fit=crop',
        title: 'Smart Fitness Tracker',
        description: 'Advanced fitness tracking with heart rate monitoring'
      },
      prompt: 'Create an engaging ad for smart fitness tracker',
      status: 'COMPLETED',
      createdAt: new Date(Date.now() - 172800000).toISOString()
    }
  ])
  const [loading, setLoading] = useState(false)
  const [showGenerateForm, setShowGenerateForm] = useState(false)
  const [showEditForm, setShowEditForm] = useState(false)
  const [editingCreative, setEditingCreative] = useState<any>(null)
  const [newCreative, setNewCreative] = useState({
    type: 'IMAGE',
    prompt: ''
  })
  const [editContent, setEditContent] = useState({
    title: '',
    description: '',
    imageUrl: ''
  })

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this creative content?')) {
      setCreatives(creatives.filter(creative => creative.id !== id))
    }
  }

  const handleEdit = (creative: any) => {
    setEditingCreative(creative)
    setEditContent({
      title: creative.content.title || '',
      description: creative.content.description || '',
      imageUrl: creative.content.imageUrl || ''
    })
    setShowEditForm(true)
  }

  const handleGenerateNew = () => {
    setShowGenerateForm(true)
  }

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    
    try {
      if (newCreative.type === 'IMAGE') {
        // Call our image generation API
        const response = await fetch('/api/generate-image', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ prompt: newCreative.prompt }),
        })
        
        const data = await response.json()
        
        if (data.success) {
          const newId = Date.now().toString()
          const createdCreative = {
            id: newId,
            type: 'IMAGE',
            content: {
              imageUrl: data.imageUrl,
              title: 'AI Generated Image',
              description: 'Image generated from prompt: ' + newCreative.prompt
            },
            prompt: newCreative.prompt,
            status: 'COMPLETED',
            createdAt: new Date().toISOString()
          }
          
          setCreatives([createdCreative, ...creatives])
        } else {
          // Fallback to placeholder if API fails
          const newId = Date.now().toString()
          const createdCreative = {
            id: newId,
            type: 'IMAGE',
            content: {
              imageUrl: `https://picsum.photos/seed/${encodeURIComponent(newCreative.prompt)}/600/400`,
              title: 'AI Generated Image',
              description: 'Image generated from prompt: ' + newCreative.prompt
            },
            prompt: newCreative.prompt,
            status: 'COMPLETED',
            createdAt: new Date().toISOString()
          }
          
          setCreatives([createdCreative, ...creatives])
        }
      } else {
        // For copy generation, we'll use a mock implementation
        const newId = Date.now().toString()
        const createdCreative = {
          id: newId,
          type: 'COPY',
          content: {
            title: 'AI Generated Copy',
            description: `This is mock AI-generated copy based on your prompt: "${newCreative.prompt}". In a full implementation, this would use open-source language models like LLaMA or Mistral.`
          },
          prompt: newCreative.prompt,
          status: 'COMPLETED',
          createdAt: new Date().toISOString()
        }
        
        setCreatives([createdCreative, ...creatives])
      }
    } catch (error) {
      console.error('Generation error:', error)
      // Fallback to placeholder
      const newId = Date.now().toString()
      const createdCreative = {
        id: newId,
        type: newCreative.type,
        content: {
          imageUrl: newCreative.type === 'IMAGE' ? `https://picsum.photos/seed/${encodeURIComponent(newCreative.prompt)}/600/400` : undefined,
          title: `Generated ${newCreative.type}`,
          description: `Content generated from prompt: ${newCreative.prompt}`
        },
        prompt: newCreative.prompt,
        status: 'COMPLETED',
        createdAt: new Date().toISOString()
      }
      
      setCreatives([createdCreative, ...creatives])
    }
    
    setNewCreative({ type: 'IMAGE', prompt: '' })
    setShowGenerateForm(false)
    setLoading(false)
  }

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const updatedCreatives = creatives.map(creative => {
      if (creative.id === editingCreative.id) {
        return {
          ...creative,
          content: {
            ...creative.content,
            title: editContent.title,
            description: editContent.description,
            imageUrl: editContent.imageUrl
          }
        }
      }
      return creative
    })
    
    setCreatives(updatedCreatives)
    setShowEditForm(false)
    setEditingCreative(null)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
        <h1 className="text-2xl font-semibold text-gray-900">Creative Studio</h1>
        <p className="mt-1 text-sm text-gray-500">Manage all your AI-generated content</p>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8 mt-6">
        {/* Edit Form Modal */}
        {showEditForm && editingCreative && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
              <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
                <h3 className="text-lg font-medium text-gray-900">Edit Creative Content</h3>
              </div>
              <form onSubmit={handleEditSubmit} className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Title</label>
                  <input
                    type="text"
                    value={editContent.title}
                    onChange={(e) => setEditContent({...editContent, title: e.target.value})}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Description</label>
                  <textarea
                    value={editContent.description}
                    onChange={(e) => setEditContent({...editContent, description: e.target.value})}
                    rows={3}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    required
                  />
                </div>
                {editingCreative.type === 'IMAGE' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Image URL</label>
                    <input
                      type="text"
                      value={editContent.imageUrl}
                      onChange={(e) => setEditContent({...editContent, imageUrl: e.target.value})}
                      className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    />
                  </div>
                )}
                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setShowEditForm(false)
                      setEditingCreative(null)
                    }}
                    className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Save Changes
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Generate Form Modal */}
        {showGenerateForm && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
              <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
                <h3 className="text-lg font-medium text-gray-900">Generate New Creative</h3>
                <p className="text-xs text-gray-500 mt-1">Using open-source AI models</p>
              </div>
              <form onSubmit={handleFormSubmit} className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Type</label>
                  <select
                    value={newCreative.type}
                    onChange={(e) => setNewCreative({...newCreative, type: e.target.value})}
                    className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                  >
                    <option value="IMAGE">Image</option>
                    <option value="COPY">Copy</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Prompt</label>
                  <textarea
                    value={newCreative.prompt}
                    onChange={(e) => setNewCreative({...newCreative, prompt: e.target.value})}
                    rows={3}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    placeholder="Describe what you want to generate..."
                    required
                  />
                </div>
                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setShowGenerateForm(false)
                      setNewCreative({ type: 'IMAGE', prompt: '' })
                    }}
                    className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                  >
                    {loading ? (
                      <>
                        <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Generating...
                      </>
                    ) : (
                      'Generate'
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-medium text-gray-900">AI Generated Content</h2>
              <button 
                onClick={handleGenerateNew}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <PlusIcon className="-ml-1 mr-2 h-5 w-5" />
                Generate New
              </button>
            </div>
          </div>

          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          ) : creatives.length === 0 ? (
            <div className="text-center py-12">
              <PhotoIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">No creatives</h3>
              <p className="mt-1 text-sm text-gray-500">Get started by generating new creative content.</p>
              <div className="mt-6">
                <button 
                  onClick={handleGenerateNew}
                  className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <PlusIcon className="-ml-1 mr-2 h-5 w-5" />
                  Generate Creative
                </button>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
              {creatives.map((creative) => (
                <div key={creative.id} className="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow">
                  <div className="p-4 border-b border-gray-100">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          {creative.type}
                        </span>
                        <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          {creative.status}
                        </span>
                      </div>
                      <div className="flex space-x-2">
                        <button 
                          onClick={() => handleEdit(creative)}
                          className="text-gray-500 hover:text-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-full p-1"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </button>
                        <button 
                          onClick={() => handleDelete(creative.id)}
                          className="text-gray-500 hover:text-red-600 focus:outline-none focus:ring-2 focus:ring-red-500 rounded-full p-1"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </div>
                    <p className="text-xs text-gray-500 mt-2">
                      {formatDate(creative.createdAt)}
                    </p>
                  </div>
                  
                  <div className="p-4">
                    {creative.type === 'IMAGE' && creative.content.imageUrl ? (
                      <img 
                        src={creative.content.imageUrl} 
                        alt={creative.content.title}
                        className="w-full h-48 object-cover rounded"
                        onError={(e) => {
                          // Handle broken images by showing a fallback
                          const target = e.target as HTMLImageElement;
                          target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPkltYWdlIE5vdCBGb3VuZDwvdGV4dD48L3N2Zz4=';
                        }}
                      />
                    ) : creative.type === 'COPY' ? (
                      <p className="text-sm text-gray-700 line-clamp-3">
                        {creative.content.description}
                      </p>
                    ) : (
                      <p className="text-sm text-gray-500">
                        {creative.prompt}
                      </p>
                    )}
                    
                    <h3 className="font-medium text-gray-900 mt-3">{creative.content.title}</h3>
                    <p className="text-sm text-gray-500 mt-1 line-clamp-2">
                      {creative.content.description}
                    </p>
                    
                    {creative.prompt && (
                      <p className="text-xs text-gray-500 mt-3 line-clamp-2">
                        Prompt: {creative.prompt}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}