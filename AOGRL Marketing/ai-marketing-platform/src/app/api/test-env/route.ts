import { NextRequest } from 'next/server'
import { apiResponse } from '@/lib/api-utils'

export async function GET() {
  // Check if Hugging Face API key is available
  const hfApiKey = process.env.HUGGING_FACE_API_KEY
  const hasApiKey = !!hfApiKey
  const apiKeyPreview = hfApiKey ? `${hfApiKey.substring(0, 5)}...${hfApiKey.substring(hfApiKey.length - 5)}` : 'Not found'
  
  return apiResponse({
    message: 'Environment variables check',
    hasHuggingFaceApiKey: hasApiKey,
    apiKeyPreview: apiKeyPreview,
    NODE_ENV: process.env.NODE_ENV,
    NEXTAUTH_URL: process.env.NEXTAUTH_URL
  })
}