import { apiResponse, apiError } from '@/lib/api-utils'

// Define allowed file types and maximum file size
const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
const MAX_FILE_SIZE = 5 * 1024 * 1024 // 5MB

export interface UploadResult {
  url: string
  filename: string
  size: number
  type: string
}

/**
 * Validates a file based on type and size
 */
export function validateFile(file: File): { isValid: boolean; error?: string } {
  // Validate file type
  if (!ALLOWED_FILE_TYPES.includes(file.type)) {
    return {
      isValid: false,
      error: `Invalid file type. Allowed types: ${ALLOWED_FILE_TYPES.join(', ')}`
    }
  }
  
  // Validate file size
  if (file.size > MAX_FILE_SIZE) {
    return {
      isValid: false,
      error: `File too large. Maximum size is ${MAX_FILE_SIZE / (1024 * 1024)}MB`
    }
  }
  
  return { isValid: true }
}

/**
 * Uploads a file to the server
 */
export async function uploadFile(file: File): Promise<{ success: boolean; data?: UploadResult; error?: string }> {
  try {
    // Validate file first
    const validation = validateFile(file)
    if (!validation.isValid) {
      return { success: false, error: validation.error }
    }
    
    // Create FormData and append file
    const formData = new FormData()
    formData.append('file', file)
    
    // Send to upload API
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData
    })
    
    if (!response.ok) {
      const errorData = await response.json()
      return { success: false, error: errorData.error || 'Failed to upload file' }
    }
    
    const result = await response.json()
    return { success: true, data: result }
  } catch (error: any) {
    console.error('File upload error:', error)
    return { success: false, error: error.message || 'Failed to upload file' }
  }
}