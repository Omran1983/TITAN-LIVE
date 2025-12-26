import { NextResponse } from 'next/server'

export async function GET() {
  try {
    // Test the image generation with a simple prompt
    const testPrompt = 'A beautiful sunset over the ocean'
    const testImageUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(testPrompt)}?width=600&height=400&seed=${Date.now()}`
    
    return NextResponse.json({
      success: true,
      imageUrl: testImageUrl,
      prompt: testPrompt,
      message: 'Test successful - API is working'
    })
  } catch (error: any) {
    console.error('Test error:', error)
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Test failed: ' + (error.message || 'Unknown error'),
        message: 'API test failed'
      },
      { status: 500 }
    )
  }
}