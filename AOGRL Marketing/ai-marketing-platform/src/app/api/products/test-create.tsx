'use client'

import { useState, useRef } from 'react'

export default function TestProductCreate() {
  const [creating, setCreating] = useState(false)
  const [result, setResult] = useState<any>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleProductCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const formData = new FormData()
    formData.append('name', 'Test Product')
    formData.append('description', 'This is a test product')
    formData.append('price', '29.99')
    formData.append('category', 'Test Category')
    
    if (fileInputRef.current?.files?.[0]) {
      formData.append('file', fileInputRef.current.files[0])
    }
    
    setCreating(true)
    
    try {
      const response = await fetch('/api/products', {
        method: 'POST',
        body: formData
      })
      
      const data = await response.json()
      setResult(data)
      
      if (response.ok) {
        alert('Product created successfully!')
      } else {
        alert(`Product creation failed: ${data.error}`)
      }
    } catch (error) {
      console.error('Product creation error:', error)
      alert('Product creation failed')
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="p-6 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-4">Test Product Creation with File Upload</h1>
      
      <form onSubmit={handleProductCreate} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">
            Select Image File (Optional)
          </label>
          <input
            type="file"
            ref={fileInputRef}
            accept="image/*"
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>
        
        <button
          type="submit"
          disabled={creating}
          className="w-full bg-green-500 text-white py-2 px-4 rounded-md hover:bg-green-600 disabled:opacity-50"
        >
          {creating ? 'Creating...' : 'Create Product'}
        </button>
      </form>
      
      {result && (
        <div className="mt-6 p-4 bg-gray-100 rounded-md">
          <h2 className="text-lg font-semibold mb-2">Creation Result:</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify(result, null, 2)}
          </pre>
        </div>
      )}
    </div>
  )
}