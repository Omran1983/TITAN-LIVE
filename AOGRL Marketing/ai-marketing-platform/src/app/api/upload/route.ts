import { NextRequest } from 'next/server'
import { writeFile, mkdir } from 'fs/promises'
import { existsSync } from 'fs'
import { join, basename } from 'path'
import { apiResponse, apiError } from '@/lib/api-utils'
import { validateFile } from '@/lib/file-upload'

export async function POST(request: NextRequest) {
  try {
    // Get the uploaded file from the request
    const formData = await request.formData()
    const file = formData.get('file') as File | null
    
    if (!file) {
      return apiError('No file uploaded')
    }
    
    // Validate file using our utility function
    const validation = validateFile(file)
    if (!validation.isValid) {
      return apiError(validation.error || 'Invalid file')
    }
    
    // Sanitize filename to prevent directory traversal attacks
    const originalName = file.name
    const sanitizedFileName = basename(originalName)
      .replace(/[^a-zA-Z0-9.-]/g, '_')
      .replace(/_{2,}/g, '_')
      .toLowerCase()
    
    // Create uploads directory if it doesn't exist
    const uploadDir = join(process.cwd(), 'public', 'uploads')
    if (!existsSync(uploadDir)) {
      await mkdir(uploadDir, { recursive: true })
    }
    
    // Convert File to Buffer
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)
    
    // Generate unique filename
    const timestamp = Date.now()
    const filename = `${timestamp}-${sanitizedFileName}`
    const filePath = join(uploadDir, filename)
    
    // Save file to disk
    await writeFile(filePath, buffer)
    
    // Return the URL where the file can be accessed
    const fileUrl = `/uploads/${filename}`
    
    return apiResponse({
      url: fileUrl,
      filename: originalName,
      size: file.size,
      type: file.type
    })
  } catch (error: any) {
    console.error('Upload API Error:', error)
    return apiError(error.message || 'Failed to upload file', 500)
  }
}