import axios from 'axios'

const FACEBOOK_API_BASE = 'https://graph.facebook.com/v18.0'
const INSTAGRAM_API_BASE = 'https://graph.instagram.com'

interface FacebookPostData {
  message: string
  link?: string
  picture?: string
  name?: string
  caption?: string
  description?: string
}

interface InstagramPostData {
  image_url?: string
  video_url?: string
  caption: string
  location_id?: string
  user_tags?: Array<{ username: string; x: number; y: number }>
}

interface SocialMediaMetrics {
  likes: number
  comments: number
  shares: number
  reach: number
  impressions: number
  engagement_rate: number
}

export class SocialMediaService {
  private facebookToken: string
  private instagramToken: string
  private pageId: string
  private threadsAppId: string
  private threadsSecret: string

  constructor() {
    this.facebookToken = process.env.META_ACCESS_TOKEN || ''
    this.instagramToken = process.env.INSTAGRAM_ACCESS_TOKEN || ''
    this.pageId = process.env.META_PAGE_ID || ''
    this.threadsAppId = process.env.THREADS_APP_ID || ''
    this.threadsSecret = process.env.THREADS_APP_SECRET || ''
  }

  private async makeRequest(url: string, method = 'GET', data?: any) {
    try {
      const config = {
        method,
        url,
        data: method !== 'GET' ? data : undefined,
        params: method === 'GET' ? data : undefined,
        timeout: 30000,
      }

      const response = await axios(config)
      return response.data
    } catch (error: any) {
      console.error('Social Media API Error:', error.response?.data || error.message)
      throw new Error(`Social Media API Error: ${error.response?.data?.error?.message || error.message}`)
    }
  }

  // === FACEBOOK PAGE MANAGEMENT ===

  // Post to Facebook Page
  async postToFacebook(postData: FacebookPostData) {
    const url = `${FACEBOOK_API_BASE}/${this.pageId}/feed`
    const data = {
      ...postData,
      access_token: this.facebookToken
    }
    
    return await this.makeRequest(url, 'POST', data)
  }

  // Get Facebook Page insights
  async getFacebookInsights(metric: string = 'page_impressions', period: string = 'day') {
    const url = `${FACEBOOK_API_BASE}/${this.pageId}/insights`
    const params = {
      metric,
      period,
      access_token: this.facebookToken
    }
    
    return await this.makeRequest(url, 'GET', params)
  }

  // Get Facebook Page posts
  async getFacebookPosts(limit: number = 25) {
    const url = `${FACEBOOK_API_BASE}/${this.pageId}/posts`
    const params = {
      fields: 'id,message,created_time,likes.summary(true),comments.summary(true),shares',
      limit,
      access_token: this.facebookToken
    }
    
    return await this.makeRequest(url, 'GET', params)
  }

  // Delete Facebook post
  async deleteFacebookPost(postId: string) {
    const url = `${FACEBOOK_API_BASE}/${postId}`
    const data = {
      access_token: this.facebookToken
    }
    
    return await this.makeRequest(url, 'DELETE', data)
  }

  // === INSTAGRAM BUSINESS MANAGEMENT ===

  // Get Instagram Business Account ID
  async getInstagramBusinessAccount() {
    const url = `${FACEBOOK_API_BASE}/${this.pageId}`
    const params = {
      fields: 'instagram_business_account',
      access_token: this.facebookToken
    }
    
    const response = await this.makeRequest(url, 'GET', params)
    return response.instagram_business_account?.id
  }

  // Post to Instagram (requires approval for content publishing)
  async postToInstagram(postData: InstagramPostData) {
    const igAccountId = await this.getInstagramBusinessAccount()
    
    // Step 1: Create media object
    const createUrl = `${FACEBOOK_API_BASE}/${igAccountId}/media`
    const createData = {
      ...postData,
      access_token: this.instagramToken
    }
    
    const mediaResponse = await this.makeRequest(createUrl, 'POST', createData)
    
    // Step 2: Publish media
    const publishUrl = `${FACEBOOK_API_BASE}/${igAccountId}/media_publish`
    const publishData = {
      creation_id: mediaResponse.id,
      access_token: this.instagramToken
    }
    
    return await this.makeRequest(publishUrl, 'POST', publishData)
  }

  // Get Instagram media
  async getInstagramMedia(limit: number = 25) {
    const igAccountId = await this.getInstagramBusinessAccount()
    const url = `${FACEBOOK_API_BASE}/${igAccountId}/media`
    const params = {
      fields: 'id,media_type,media_url,thumbnail_url,permalink,caption,timestamp,like_count,comments_count',
      limit,
      access_token: this.instagramToken
    }
    
    return await this.makeRequest(url, 'GET', params)
  }

  // Get Instagram insights
  async getInstagramInsights(mediaId: string) {
    const url = `${FACEBOOK_API_BASE}/${mediaId}/insights`
    const params = {
      metric: 'engagement,impressions,reach,saved',
      access_token: this.instagramToken
    }
    
    return await this.makeRequest(url, 'GET', params)
  }

  // === THREADS INTEGRATION ===

  // Post to Threads (when API becomes available)
  async postToThreads(text: string, mediaUrls?: string[]) {
    // Note: Threads API is limited and may require special access
    console.warn('Threads API integration pending full availability')
    
    // Placeholder for future Threads API integration
    return {
      success: false,
      message: 'Threads API integration pending',
      data: { text, mediaUrls }
    }
  }

  // === ANALYTICS AND REPORTING ===

  // Get comprehensive social media metrics
  async getSocialMediaMetrics(dateRange: { start: string; end: string }): Promise<{
    facebook: SocialMediaMetrics;
    instagram: SocialMediaMetrics;
  }> {
    try {
      // Facebook metrics
      const fbInsights = await this.getFacebookInsights('page_post_engagements,page_impressions,page_reach', 'day')
      
      // Instagram metrics
      const igAccountId = await this.getInstagramBusinessAccount()
      const igInsights = await this.makeRequest(
        `${FACEBOOK_API_BASE}/${igAccountId}/insights`,
        'GET',
        {
          metric: 'impressions,reach,profile_views',
          period: 'day',
          access_token: this.instagramToken
        }
      )

      return {
        facebook: this.parseFacebookMetrics(fbInsights),
        instagram: this.parseInstagramMetrics(igInsights)
      }
    } catch (error) {
      console.error('Error fetching social media metrics:', error)
      return {
        facebook: this.getEmptyMetrics(),
        instagram: this.getEmptyMetrics()
      }
    }
  }

  // Cross-platform posting
  async postToAllPlatforms(content: {
    text: string;
    imageUrl?: string;
    link?: string;
  }) {
    const results = {
      facebook: null as any,
      instagram: null as any,
      threads: null as any,
      errors: [] as string[]
    }

    // Post to Facebook
    try {
      results.facebook = await this.postToFacebook({
        message: content.text,
        link: content.link,
        picture: content.imageUrl
      })
    } catch (error: any) {
      results.errors.push(`Facebook: ${error.message}`)
    }

    // Post to Instagram (if image provided)
    if (content.imageUrl) {
      try {
        results.instagram = await this.postToInstagram({
          image_url: content.imageUrl,
          caption: content.text
        })
      } catch (error: any) {
        results.errors.push(`Instagram: ${error.message}`)
      }
    }

    // Post to Threads (when available)
    try {
      results.threads = await this.postToThreads(content.text, content.imageUrl ? [content.imageUrl] : undefined)
    } catch (error: any) {
      results.errors.push(`Threads: ${error.message}`)
    }

    return results
  }

  // === HELPER METHODS ===

  private parseFacebookMetrics(insights: any): SocialMediaMetrics {
    // Parse Facebook insights data
    const data = insights.data || []
    return {
      likes: this.extractMetricValue(data, 'page_fan_adds') || 0,
      comments: this.extractMetricValue(data, 'page_post_engagements') || 0,
      shares: 0, // Not directly available in insights
      reach: this.extractMetricValue(data, 'page_reach') || 0,
      impressions: this.extractMetricValue(data, 'page_impressions') || 0,
      engagement_rate: 0 // Calculate based on available data
    }
  }

  private parseInstagramMetrics(insights: any): SocialMediaMetrics {
    // Parse Instagram insights data
    const data = insights.data || []
    return {
      likes: 0, // Not directly available in account insights
      comments: 0,
      shares: 0,
      reach: this.extractMetricValue(data, 'reach') || 0,
      impressions: this.extractMetricValue(data, 'impressions') || 0,
      engagement_rate: 0
    }
  }

  private extractMetricValue(data: any[], metricName: string): number {
    const metric = data.find(item => item.name === metricName)
    return metric?.values?.[0]?.value || 0
  }

  private getEmptyMetrics(): SocialMediaMetrics {
    return {
      likes: 0,
      comments: 0,
      shares: 0,
      reach: 0,
      impressions: 0,
      engagement_rate: 0
    }
  }

  // Validate tokens
  async validateTokens() {
    const results = {
      facebook: false,
      instagram: false,
      threads: false
    }

    try {
      await this.makeRequest(`${FACEBOOK_API_BASE}/me`, 'GET', { access_token: this.facebookToken })
      results.facebook = true
    } catch (error) {
      console.error('Facebook token validation failed:', error)
    }

    try {
      const igAccount = await this.getInstagramBusinessAccount()
      results.instagram = !!igAccount
    } catch (error) {
      console.error('Instagram token validation failed:', error)
    }

    // Threads validation pending API availability
    results.threads = false

    return results
  }

  // Get account information
  async getAccountInfo() {
    try {
      const [fbInfo, igAccountId] = await Promise.all([
        this.makeRequest(`${FACEBOOK_API_BASE}/${this.pageId}`, 'GET', {
          fields: 'name,category,fan_count,followers_count',
          access_token: this.facebookToken
        }),
        this.getInstagramBusinessAccount()
      ])

      let igInfo = null
      if (igAccountId) {
        igInfo = await this.makeRequest(`${FACEBOOK_API_BASE}/${igAccountId}`, 'GET', {
          fields: 'followers_count,media_count,name,username',
          access_token: this.instagramToken
        })
      }

      return {
        facebook: fbInfo,
        instagram: igInfo,
        pageId: this.pageId,
        instagramAccountId: igAccountId
      }
    } catch (error) {
      console.error('Error fetching account info:', error)
      return null
    }
  }
}

export const socialMediaService = new SocialMediaService()