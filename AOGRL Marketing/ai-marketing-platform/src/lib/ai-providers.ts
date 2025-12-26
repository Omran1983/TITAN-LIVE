import { huggingFaceService } from '@/lib/huggingface-service'

export interface CreativeRequest {
  type: 'IMAGE' | 'COPY' | 'VIDEO'
  prompt: string
  productIds?: string[]
  audience?: string
}

export interface CreativeResponse {
  id: string
  type: 'IMAGE' | 'COPY' | 'VIDEO'
  content: {
    imageUrl?: string
    title?: string
    description?: string
    cta?: string
    videoUrl?: string
    text?: string
  }
  status: 'COMPLETED' | 'FAILED'
  error?: string
}

export interface AnalyticsData {
  impressions: number
  clicks: number
  conversions: number
  spend: number
  revenue: number
}

class MockAIProvider {
  async generateCreative(request: CreativeRequest): Promise<CreativeResponse> {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    const mockImages = [
      'https://picsum.photos/800/600?random=1',
      'https://picsum.photos/800/600?random=2',
      'https://picsum.photos/800/600?random=3',
      'https://picsum.photos/800/600?random=4',
      'https://picsum.photos/800/600?random=5'
    ]
    
    const mockTitles = [
      'Discover Amazing Products',
      'Transform Your Experience',
      'Exclusive Limited Offer',
      'Premium Quality Guaranteed',
      'Innovation Meets Style'
    ]
    
    const mockDescriptions = [
      'Experience the difference with our premium products designed for modern living.',
      'Join thousands of satisfied customers who have transformed their lives.',
      'Don\'t miss out on this exclusive opportunity to save big.',
      'Quality craftsmanship meets innovative design in every product.',
      'Elevate your lifestyle with our cutting-edge solutions.'
    ]
    
    const mockCTAs = [
      'Shop Now',
      'Learn More',
      'Get Started',
      'Order Today',
      'Discover More'
    ]
    
    const randomIndex = Math.floor(Math.random() * 5)
    
    let content: any = {}
    
    switch (request.type) {
      case 'IMAGE':
        content = {
          imageUrl: mockImages[randomIndex],
          title: mockTitles[randomIndex],
          description: mockDescriptions[randomIndex],
          cta: mockCTAs[randomIndex]
        }
        break
      case 'COPY':
        content = {
          title: mockTitles[randomIndex],
          description: mockDescriptions[randomIndex],
          cta: mockCTAs[randomIndex]
        }
        break
      case 'VIDEO':
        content = {
          videoUrl: `https://sample-videos.com/zip/10/mp4/SampleVideo_${randomIndex + 1}.mp4`,
          title: mockTitles[randomIndex],
          description: mockDescriptions[randomIndex],
          cta: mockCTAs[randomIndex]
        }
        break
    }
    
    return {
      id: `mock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      type: request.type,
      content,
      status: 'COMPLETED'
    }
  }
  
  async generateAnalytics(campaignId: string, dateRange: { start: Date, end: Date }): Promise<AnalyticsData[]> {
    const days = Math.ceil((dateRange.end.getTime() - dateRange.start.getTime()) / (1000 * 60 * 60 * 24))
    const analytics: AnalyticsData[] = []
    
    for (let i = 0; i < days; i++) {
      const baseImpressions = Math.floor(Math.random() * 10000) + 1000
      const clicks = Math.floor(baseImpressions * (Math.random() * 0.05 + 0.01)) // 1-6% CTR
      const conversions = Math.floor(clicks * (Math.random() * 0.1 + 0.02)) // 2-12% conversion rate
      const spend = Math.random() * 500 + 100 // $100-600 daily spend
      const revenue = conversions * (Math.random() * 100 + 50) // $50-150 per conversion
      
      analytics.push({
        impressions: baseImpressions,
        clicks,
        conversions,
        spend: Math.round(spend * 100) / 100,
        revenue: Math.round(revenue * 100) / 100
      })
    }
    
    return analytics
  }
}

class HuggingFaceProvider {
  async generateCreative(request: CreativeRequest): Promise<CreativeResponse> {
    try {
      let content: any = {}
      
      switch (request.type) {
        case 'IMAGE':
          // For images, we'll generate a description and then use that for image generation
          const imagePrompt = `Create a marketing image for: ${request.prompt}. Professional, high-quality, commercial use.`
          content = {
            title: `Marketing Image for ${request.prompt.substring(0, 30)}...`,
            description: request.prompt,
            imageUrl: `https://via.placeholder.com/800x600/667eea/ffffff?text=${encodeURIComponent(request.prompt.substring(0, 20))}`
          }
          break
          
        case 'COPY':
          // Use Hugging Face for text generation
          try {
            const generatedText = await huggingFaceService.generateMarketingCopy(request.prompt)
            content = {
              text: Array.isArray(generatedText) ? generatedText[0].summary_text : 'Generated marketing copy',
              title: `Generated Copy for ${request.prompt.substring(0, 30)}...`,
              description: request.prompt
            }
          } catch (error) {
            // Fallback to mock if Hugging Face fails
            content = {
              text: `Professional marketing copy for: ${request.prompt}`,
              title: `Generated Copy for ${request.prompt.substring(0, 30)}...`,
              description: request.prompt
            }
          }
          break
          
        case 'VIDEO':
          content = {
            videoUrl: `https://sample-videos.com/zip/10/mp4/SampleVideo_1.mp4`,
            title: `Marketing Video for ${request.prompt.substring(0, 30)}...`,
            description: request.prompt
          }
          break
      }
      
      return {
        id: `hf_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        type: request.type,
        content,
        status: 'COMPLETED'
      }
    } catch (error: any) {
      return {
        id: `hf_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        type: request.type,
        content: {},
        status: 'FAILED',
        error: error.message || 'Failed to generate creative with Hugging Face'
      }
    }
  }
  
  async generateAnalytics(campaignId: string, dateRange: { start: Date, end: Date }): Promise<AnalyticsData[]> {
    // Use mock analytics for now
    return new MockAIProvider().generateAnalytics(campaignId, dateRange)
  }
}

class MetaProvider {
  constructor(private accessToken: string) {}
  
  async generateCreative(request: CreativeRequest): Promise<CreativeResponse> {
    // This would integrate with Meta's Creative API
    throw new Error('Meta provider not implemented - set PROVIDER=mock for demo')
  }
  
  async generateAnalytics(campaignId: string, dateRange: { start: Date, end: Date }): Promise<AnalyticsData[]> {
    // This would integrate with Meta's Analytics API
    throw new Error('Meta provider not implemented - set PROVIDER=mock for demo')
  }
}

class TikTokProvider {
  constructor(private accessToken: string) {}
  
  async generateCreative(request: CreativeRequest): Promise<CreativeResponse> {
    // This would integrate with TikTok's Creative API
    throw new Error('TikTok provider not implemented - set PROVIDER=mock for demo')
  }
  
  async generateAnalytics(campaignId: string, dateRange: { start: Date, end: Date }): Promise<AnalyticsData[]> {
    // This would integrate with TikTok's Analytics API
    throw new Error('TikTok provider not implemented - set PROVIDER=mock for demo')
  }
}

export function getAIProvider() {
  const provider = process.env.PROVIDER || 'mock'
  
  switch (provider) {
    case 'mock':
      return new MockAIProvider()
    case 'huggingface':
      return new HuggingFaceProvider()
    case 'meta':
      if (!process.env.META_ACCESS_TOKEN) {
        console.warn('META_ACCESS_TOKEN not set, falling back to mock provider')
        return new MockAIProvider()
      }
      return new MetaProvider(process.env.META_ACCESS_TOKEN)
    case 'tiktok':
      if (!process.env.TIKTOK_ACCESS_TOKEN) {
        console.warn('TIKTOK_ACCESS_TOKEN not set, falling back to mock provider')
        return new MockAIProvider()
      }
      return new TikTokProvider(process.env.TIKTOK_ACCESS_TOKEN)
    default:
      return new MockAIProvider()
  }
}