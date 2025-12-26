import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { prompt } = await request.json()
    
    // Simple placeholder that changes based on the prompt
    const imageUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=600&height=400&seed=${Date.now()}`
    
    return NextResponse.json({
      success: true,
      imageUrl: imageUrl,
      prompt: prompt,
      message: 'Image generated successfully'
    })
  } catch (error: any) {
    console.error('Image generation error:', error)
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to generate image: ' + (error.message || 'Unknown error'),
        message: 'Using fallback image'
      },
      { status: 500 }
    )
  }
}