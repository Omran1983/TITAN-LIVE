'use client'

import { useState, useRef } from 'react'

export default function TestUpload() {
  const [uploading, setUploading] = useState(false)
  const [result, setResult] = useState<any>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileUpload = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!fileInputRef.current?.files?.[0]) {
      alert('Please select a file first')
      return
    }
    
    setUploading(true)
    
    try {
      const file = fileInputRef.current.files[0]
      const formData = new FormData()
      formData.append('file', file)
      
      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData
      })
      
      const data = await response.json()
      setResult(data)
      
      if (response.ok) {
        alert('File uploaded successfully!')
      } else {
        alert(`Upload failed: ${data.error}`)
      }
    } catch (error) {
      console.error('Upload error:', error)
      alert('Upload failed')
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="p-6 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-4">Test File Upload</h1>
      
      <form onSubmit={handleFileUpload} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">
            Select Image File
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
          disabled={uploading}
          className="w-full bg-blue-500 text-white py-2 px-4 rounded-md hover:bg-blue-600 disabled:opacity-50"
        >
          {uploading ? 'Uploading...' : 'Upload File'}
        </button>
      </form>
      
      {result && (
        <div className="mt-6 p-4 bg-gray-100 rounded-md">
          <h2 className="text-lg font-semibold mb-2">Upload Result:</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify(result, null, 2)}
          </pre>
          
          {result.url && (
            <div className="mt-4">
              <h3 className="font-medium mb-2">Image Preview:</h3>
              <img 
                src={result.url} 
                alt="Uploaded preview" 
                className="max-w-full h-auto border rounded"
              />
            </div>
          )}
        </div>
      )}
    </div>
  )
}