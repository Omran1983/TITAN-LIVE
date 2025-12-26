import { BaseScraper, ScrapedData, ScraperConfig } from './base-scraper'

export interface SocialMediaMetrics {
  platform: string
  followers: number
  following: number
  posts: number
  engagement: {
    likes: number
    comments: number
    shares: number
    views: number
  }
  recentPosts: {
    id: string
    content: string
    likes: number
    comments: number
    shares: number
    hashtags: string[]
    mentions: string[]
    timestamp: string
  }[]
  topHashtags: string[]
  averageEngagement: number
  engagementRate: number
}

export class SocialMediaScraper extends BaseScraper {
  constructor(config: ScraperConfig = {}) {
    super({
      delay: 3000, // Social media sites are strict about rate limiting
      retries: 2,
      ...config
    })
  }

  async scrape(url: string): Promise<ScrapedData> {
    const $ = await this.fetchPage(url)
    
    const platform = this.detectPlatform(url)
    const socialData = await this.extractSocialData($, platform, url)
    const hash = this.generateHash(socialData)

    return {
      url,
      title: this.extractText($, 'title'),
      content: socialData,
      metadata: {
        scrapeType: 'social_media_metrics',
        platform,
        followers: socialData.followers,
        engagementRate: socialData.engagementRate
      },
      hash,
      scrapedAt: new Date()
    }
  }

  private detectPlatform(url: string): string {
    if (url.includes('instagram.com')) return 'instagram'
    if (url.includes('facebook.com')) return 'facebook'
    if (url.includes('twitter.com') || url.includes('x.com')) return 'twitter'
    if (url.includes('linkedin.com')) return 'linkedin'
    if (url.includes('tiktok.com')) return 'tiktok'
    if (url.includes('youtube.com')) return 'youtube'
    return 'unknown'
  }

  private async extractSocialData($: any, platform: string, url: string): Promise<SocialMediaMetrics> {
    let selectors: Record<string, string> = {}

    // Platform-specific selectors
    switch (platform) {
      case 'instagram':
        selectors = {
          followers: 'a[href*="/followers/"] span, meta[property="og:description"]',
          following: 'a[href*="/following/"] span',
          posts: 'header section ul li span',
          postContent: 'article div div div div span',
          postLikes: 'section button span',
          postComments: 'section a span',
          hashtags: 'a[href*="/explore/tags/"]'
        }
        break
      case 'twitter':
      case 'x':
        selectors = {
          followers: 'a[href*="/followers"] span span',
          following: 'a[href*="/following"] span span',
          posts: 'div[data-testid="tweet"]',
          postContent: 'div[data-testid="tweetText"]',
          postLikes: 'div[data-testid="like"] span',
          postComments: 'div[data-testid="reply"] span',
          hashtags: 'a[href*="/hashtag/"]'
        }
        break
      case 'linkedin':
        selectors = {
          followers: '.pv-recent-activity-top-card__follower-count',
          following: '.pv-recent-activity-top-card__following-count',
          posts: '.feed-shared-update-v2',
          postContent: '.feed-shared-text span span',
          postLikes: '.social-counts-reactions__count',
          postComments: '.social-counts-comments__count'
        }
        break
      default:
        // Generic selectors
        selectors = {
          followers: '[data-followers], .followers, .follower-count',
          following: '[data-following], .following, .following-count',
          posts: '.post, .update, .tweet, article',
          postContent: '.content, .text, .caption',
          postLikes: '.likes, .like-count, [data-likes]',
          postComments: '.comments, .comment-count, [data-comments]'
        }
    }

    // Extract basic metrics
    const followersText = this.extractText($, selectors.followers)
    const followingText = this.extractText($, selectors.following)
    
    const followers = this.parseCount(followersText)
    const following = this.parseCount(followingText)

    // Extract recent posts
    const recentPosts = this.extractPosts($, selectors)
    
    // Calculate engagement metrics
    const totalLikes = recentPosts.reduce((sum, post) => sum + post.likes, 0)
    const totalComments = recentPosts.reduce((sum, post) => sum + post.comments, 0)
    const totalShares = recentPosts.reduce((sum, post) => sum + post.shares, 0)
    
    const totalEngagement = totalLikes + totalComments + totalShares
    const averageEngagement = recentPosts.length > 0 ? totalEngagement / recentPosts.length : 0
    const engagementRate = followers > 0 ? (averageEngagement / followers) * 100 : 0

    // Extract hashtags
    const allHashtags = recentPosts.flatMap(post => post.hashtags)
    const topHashtags = this.getTopHashtags(allHashtags)

    return {
      platform,
      followers,
      following,
      posts: recentPosts.length,
      engagement: {
        likes: totalLikes,
        comments: totalComments,
        shares: totalShares,
        views: 0 // Views are harder to scrape reliably
      },
      recentPosts,
      topHashtags,
      averageEngagement,
      engagementRate
    }
  }

  private extractPosts($: any, selectors: Record<string, string>): any[] {
    const posts: any[] = []
    
    $(selectors.posts).slice(0, 10).each((index, element) => {
      const $post = $(element)
      
      const content = this.extractText($post, selectors.postContent)
      const likesText = this.extractText($post, selectors.postLikes)
      const commentsText = this.extractText($post, selectors.postComments)
      
      const likes = this.parseCount(likesText)
      const comments = this.parseCount(commentsText)
      
      // Extract hashtags from content
      const hashtags = this.extractHashtags(content)
      const mentions = this.extractMentions(content)
      
      posts.push({
        id: `post_${index}`,
        content: content.substring(0, 200), // Limit content length
        likes,
        comments,
        shares: 0, // Shares are platform-specific and harder to extract
        hashtags,
        mentions,
        timestamp: new Date().toISOString() // Would need more sophisticated date extraction
      })
    })
    
    return posts
  }

  private parseCount(text: string): number {
    if (!text) return 0
    
    // Handle abbreviated numbers (1.2K, 1.5M, etc.)
    const cleanText = text.replace(/[^\d.KMB]/gi, '').toLowerCase()
    const number = parseFloat(cleanText)
    
    if (cleanText.includes('k')) return Math.floor(number * 1000)
    if (cleanText.includes('m')) return Math.floor(number * 1000000)
    if (cleanText.includes('b')) return Math.floor(number * 1000000000)
    
    return Math.floor(number) || 0
  }

  private extractHashtags(text: string): string[] {
    const hashtagRegex = /#([a-zA-Z0-9_]+)/g
    const matches = text.match(hashtagRegex) || []
    return matches.map(tag => tag.substring(1)) // Remove # symbol
  }

  private extractMentions(text: string): string[] {
    const mentionRegex = /@([a-zA-Z0-9_]+)/g
    const matches = text.match(mentionRegex) || []
    return matches.map(mention => mention.substring(1)) // Remove @ symbol
  }

  private getTopHashtags(hashtags: string[]): string[] {
    const hashtagCounts: Record<string, number> = {}
    
    hashtags.forEach(tag => {
      hashtagCounts[tag] = (hashtagCounts[tag] || 0) + 1
    })
    
    return Object.entries(hashtagCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([tag]) => tag)
  }
}