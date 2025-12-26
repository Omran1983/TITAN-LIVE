'use client'

import { useState, useRef } from 'react'
import { uploadFile } from '@/lib/file-upload'

export default function TestFileUpload() {
  const [uploading, setUploading] = useState(false)
  const [result, setResult] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileUpload = async () => {
    if (!fileInputRef.current?.files?.[0]) {
      setError('Please select a file first')
      return
    }
    
    setUploading(true)
    setError(null)
    setResult(null)
    
    try {
      const file = fileInputRef.current.files[0]
      const uploadResult = await uploadFile(file)
      
      if (uploadResult.success) {
        setResult(uploadResult.data)
      } else {
        setError(uploadResult.error || 'Upload failed')
      }
    } catch (err) {
      setError('An unexpected error occurred')
      console.error('Upload error:', err)
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Test File Upload</h1>
      
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Select Image File
          </label>
          <input
            type="file"
            ref={fileInputRef}
            accept="image/*"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <button
          onClick={handleFileUpload}
          disabled={uploading}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {uploading ? 'Uploading...' : 'Upload File'}
        </button>
        
        {error && (
          <div className="mt-4 p-3 bg-red-50 text-red-700 rounded-md">
            <strong>Error:</strong> {error}
          </div>
        )}
        
        {result && (
          <div className="mt-6 p-4 bg-green-50 rounded-md">
            <h2 className="text-lg font-semibold text-green-800 mb-2">Upload Successful!</h2>
            <div className="space-y-2 text-sm text-green-700">
              <p><strong>Filename:</strong> {result.filename}</p>
              <p><strong>Size:</strong> {(result.size / 1024).toFixed(1)} KB</p>
              <p><strong>Type:</strong> {result.type}</p>
              <p><strong>URL:</strong> <a href={result.url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">{result.url}</a></p>
            </div>
            
            {result.url && (
              <div className="mt-4">
                <h3 className="font-medium text-green-800 mb-2">Image Preview:</h3>
                <img 
                  src={result.url} 
                  alt="Uploaded preview" 
                  className="max-w-full h-auto border rounded"
                  onError={(e) => {
                    const target = e.target as HTMLImageElement
                    target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iMzIiIHk9IjMyIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTIiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPg=='
                  }}
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}