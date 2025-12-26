// Advanced Analytics Service with AI-powered Predictive Insights
import { prisma } from './prisma'

export interface PredictiveAnalyticsRequest {
  campaignIds?: string[]
  timeframe: 'daily' | 'weekly' | 'monthly' | 'quarterly'
  predictDays: number
  metrics: ('impressions' | 'clicks' | 'conversions' | 'revenue' | 'spend')[]
  includeSeasonality: boolean
  confidenceLevel: 0.8 | 0.9 | 0.95
}

export interface CampaignInsight {
  campaignId: string
  campaignName: string
  insightType: 'opportunity' | 'warning' | 'optimization' | 'anomaly'
  severity: 'low' | 'medium' | 'high'
  title: string
  description: string
  recommendedActions: string[]
  potentialImpact: {
    metric: string
    improvement: number
    confidence: number
  }
  priority: number
}

export interface AnalyticsReport {
  id: string
  reportType: 'performance' | 'predictive' | 'comparative' | 'attribution'
  timeframe: string
  generatedAt: string
  insights: CampaignInsight[]
  summary: {
    totalImpact: number
    confidence: number
    keyFindings: string[]
    nextSteps: string[]
  }
}

export class AdvancedAnalyticsService {
  // Generate comprehensive analytics report
  async generateReport(
    type: 'performance' | 'predictive' | 'comparative' | 'attribution',
    request: PredictiveAnalyticsRequest,
    tenantId: string
  ): Promise<AnalyticsReport> {
    const campaigns = await this.getCampaignData(request.campaignIds, tenantId)
    
    let insights: CampaignInsight[] = []
    
    switch (type) {
      case 'performance':
        insights = await this.generatePerformanceInsights(campaigns)
        break
      case 'predictive':
        insights = await this.generatePredictiveInsights(campaigns, request)
        break
      case 'comparative':
        insights = await this.generateComparativeInsights(campaigns)
        break
      case 'attribution':
        insights = await this.generateAttributionInsights(campaigns)
        break
    }

    const summary = this.generateReportSummary(insights)

    return {
      id: this.generateReportId(),
      reportType: type,
      timeframe: request.timeframe,
      generatedAt: new Date().toISOString(),
      insights,
      summary
    }
  }

  // Real-time anomaly detection
  async detectAnomalies(tenantId: string): Promise<{
    anomalies: Array<{
      campaignId: string
      campaignName: string
      metric: string
      currentValue: number
      expectedValue: number
      deviation: number
      severity: 'low' | 'medium' | 'high'
      detectedAt: string
      possibleCauses: string[]
    }>
    summary: {
      totalAnomalies: number
      highSeverityCount: number
      impactedCampaigns: number
    }
  }> {
    const campaigns = await this.getActiveCampaigns(tenantId)
    const anomalies = []

    for (const campaign of campaigns) {
      const recentAnalytics = await this.getRecentAnalytics(campaign.id, 7)
      const historicalBaseline = await this.calculateBaseline(campaign.id, 30)
      
      const campaignAnomalies = this.detectCampaignAnomalies(
        campaign,
        recentAnalytics,
        historicalBaseline
      )
      
      anomalies.push(...campaignAnomalies)
    }

    return {
      anomalies,
      summary: {
        totalAnomalies: anomalies.length,
        highSeverityCount: anomalies.filter(a => a.severity === 'high').length,
        impactedCampaigns: new Set(anomalies.map(a => a.campaignId)).size
      }
    }
  }

  // Attribution modeling
  async generateAttributionAnalysis(campaignId: string): Promise<{
    touchpoints: Array<{
      source: string
      channel: string
      position: 'first_click' | 'last_click' | 'assisted'
      attributedConversions: number
      attributedRevenue: number
      attribution_percentage: number
    }>
    models: {
      first_click: { conversions: number; revenue: number }
      last_click: { conversions: number; revenue: number }
      linear: { conversions: number; revenue: number }
      time_decay: { conversions: number; revenue: number }
      data_driven: { conversions: number; revenue: number }
    }
    insights: string[]
  }> {
    // Mock attribution data
    const touchpoints = [
      {
        source: 'Google Ads',
        channel: 'paid_search',
        position: 'first_click' as const,
        attributedConversions: 45,
        attributedRevenue: 12500,
        attribution_percentage: 35
      },
      {
        source: 'Facebook Ads',
        channel: 'social_paid',
        position: 'assisted' as const,
        attributedConversions: 32,
        attributedRevenue: 8900,
        attribution_percentage: 25
      },
      {
        source: 'Email Marketing',
        channel: 'email',
        position: 'last_click' as const,
        attributedConversions: 28,
        attributedRevenue: 7600,
        attribution_percentage: 20
      }
    ]

    const models = {
      first_click: { conversions: 135, revenue: 37000 },
      last_click: { conversions: 135, revenue: 37000 },
      linear: { conversions: 135, revenue: 37000 },
      time_decay: { conversions: 135, revenue: 37000 },
      data_driven: { conversions: 135, revenue: 37000 }
    }

    const insights = [
      'Google Ads drives the highest first-touch attribution value',
      'Email marketing shows strong last-click conversion performance',
      'Social channels provide significant assisted conversions'
    ]

    return { touchpoints, models, insights }
  }

  // Market intelligence insights
  async generateMarketIntelligence(industry: string): Promise<{
    market_trends: {
      trend: string
      impact: 'positive' | 'negative' | 'neutral'
      confidence: number
      timeframe: string
    }[]
    competitive_analysis: {
      competitor: string
      market_share: number
      growth_rate: number
      key_strengths: string[]
      opportunities: string[]
    }[]
    recommendations: {
      strategy: string
      priority: 'high' | 'medium' | 'low'
      expected_impact: string
      implementation_difficulty: 'easy' | 'medium' | 'hard'
    }[]
  }> {
    const market_trends = [
      {
        trend: 'Increased focus on privacy-first marketing',
        impact: 'positive' as const,
        confidence: 0.85,
        timeframe: 'Q2-Q4 2024'
      },
      {
        trend: 'AI-powered personalization adoption',
        impact: 'positive' as const,
        confidence: 0.92,
        timeframe: 'H2 2024'
      }
    ]

    const competitive_analysis = [
      {
        competitor: 'Market Leader A',
        market_share: 25.3,
        growth_rate: 15.2,
        key_strengths: ['Strong brand recognition', 'Advanced AI capabilities'],
        opportunities: ['Limited SMB focus', 'Higher pricing']
      }
    ]

    const recommendations = [
      {
        strategy: 'Develop first-party data collection strategy',
        priority: 'high' as const,
        expected_impact: 'Maintain targeting effectiveness',
        implementation_difficulty: 'medium' as const
      }
    ]

    return { market_trends, competitive_analysis, recommendations }
  }

  // Private helper methods
  private async getCampaignData(campaignIds: string[] | undefined, tenantId: string) {
    const whereClause: any = { tenantId, status: 'RUNNING' }
    if (campaignIds && campaignIds.length > 0) {
      whereClause.id = { in: campaignIds }
    }

    return await prisma.campaign.findMany({
      where: whereClause,
      include: {
        analytics: {
          orderBy: { createdAt: 'desc' },
          take: 90
        },
        client: true,
        products: { include: { product: true } }
      }
    })
  }

  private async generatePerformanceInsights(campaigns: any[]): Promise<CampaignInsight[]> {
    const insights: CampaignInsight[] = []

    for (const campaign of campaigns) {
      const analytics = campaign.analytics
      if (analytics.length === 0) continue

      const recentMetrics = this.calculateRecentMetrics(analytics)
      const historicalMetrics = this.calculateHistoricalMetrics(analytics)
      
      const performanceTrend = this.calculatePerformanceTrend(recentMetrics, historicalMetrics)
      
      if (performanceTrend.isImproving) {
        insights.push({
          campaignId: campaign.id,
          campaignName: campaign.name,
          insightType: 'opportunity',
          severity: 'medium',
          title: 'Strong Performance Trend',
          description: `Campaign showing ${performanceTrend.improvementPercent}% improvement`,
          recommendedActions: [
            'Consider increasing budget allocation',
            'Scale successful creative elements'
          ],
          potentialImpact: {
            metric: 'revenue',
            improvement: performanceTrend.improvementPercent * 1.5,
            confidence: 0.75
          },
          priority: 8
        })
      }

      const efficiency = this.calculateEfficiency(analytics)
      if (efficiency.isInefficient) {
        insights.push({
          campaignId: campaign.id,
          campaignName: campaign.name,
          insightType: 'optimization',
          severity: 'high',
          title: 'Budget Efficiency Opportunity',
          description: `Campaign CPA is ${efficiency.cpaIncrease}% above optimal`,
          recommendedActions: [
            'Review and optimize targeting',
            'Test new creative variations'
          ],
          potentialImpact: {
            metric: 'cost_reduction',
            improvement: efficiency.potentialSavings,
            confidence: 0.85
          },
          priority: 9
        })
      }
    }

    return insights.sort((a, b) => b.priority - a.priority)
  }

  private async generatePredictiveInsights(campaigns: any[], request: PredictiveAnalyticsRequest): Promise<CampaignInsight[]> {
    // Mock predictive insights
    return [{
      campaignId: 'all',
      campaignName: 'Portfolio',
      insightType: 'opportunity',
      severity: 'medium',
      title: 'Growth Trajectory Predicted',
      description: 'Models show 15% revenue growth trend',
      recommendedActions: ['Scale successful strategies'],
      potentialImpact: {
        metric: 'revenue',
        improvement: 15,
        confidence: 0.8
      },
      priority: 7
    }]
  }

  private async generateComparativeInsights(campaigns: any[]): Promise<CampaignInsight[]> {
    // Mock comparative insights
    return campaigns.map(campaign => ({
      campaignId: campaign.id,
      campaignName: campaign.name,
      insightType: 'optimization' as const,
      severity: 'medium' as const,
      title: 'Performance vs Benchmark',
      description: 'Campaign performing above industry average',
      recommendedActions: ['Maintain current strategy'],
      potentialImpact: {
        metric: 'efficiency',
        improvement: 10,
        confidence: 0.7
      },
      priority: 5
    }))
  }

  private async generateAttributionInsights(campaigns: any[]): Promise<CampaignInsight[]> {
    // Mock attribution insights
    return [{
      campaignId: 'all',
      campaignName: 'Attribution Analysis',
      insightType: 'optimization',
      severity: 'medium',
      title: 'Multi-Touch Attribution Opportunity',
      description: 'First-click channels undervalued',
      recommendedActions: ['Rebalance attribution model'],
      potentialImpact: {
        metric: 'accuracy',
        improvement: 20,
        confidence: 0.75
      },
      priority: 6
    }]
  }

  private generateReportSummary(insights: CampaignInsight[]) {
    const highPriorityInsights = insights.filter(i => i.priority >= 8)
    const totalPotentialImpact = insights.reduce((sum, i) => sum + i.potentialImpact.improvement, 0)
    const avgConfidence = insights.reduce((sum, i) => sum + i.potentialImpact.confidence, 0) / insights.length

    return {
      totalImpact: Math.round(totalPotentialImpact),
      confidence: Math.round(avgConfidence * 100),
      keyFindings: [
        `${highPriorityInsights.length} high-priority opportunities identified`,
        `Potential ${totalPotentialImpact.toFixed(1)}% improvement available`,
        `${insights.filter(i => i.insightType === 'opportunity').length} growth opportunities detected`
      ],
      nextSteps: [
        'Review high-priority insights and implement actions',
        'Monitor metrics for trend detection',
        'Set up automated alerts'
      ]
    }
  }

  private calculateRecentMetrics(analytics: any[]) {
    const recent = analytics.slice(0, 7)
    return {
      avgRevenue: recent.reduce((sum, a) => sum + a.revenue, 0) / recent.length,
      avgConversions: recent.reduce((sum, a) => sum + a.conversions, 0) / recent.length,
      avgSpend: recent.reduce((sum, a) => sum + a.spend, 0) / recent.length
    }
  }

  private calculateHistoricalMetrics(analytics: any[]) {
    const historical = analytics.slice(14, 28)
    return {
      avgRevenue: historical.reduce((sum, a) => sum + a.revenue, 0) / historical.length,
      avgConversions: historical.reduce((sum, a) => sum + a.conversions, 0) / historical.length,
      avgSpend: historical.reduce((sum, a) => sum + a.spend, 0) / historical.length
    }
  }

  private calculatePerformanceTrend(recent: any, historical: any) {
    const revenueChange = historical.avgRevenue > 0 ? 
      ((recent.avgRevenue - historical.avgRevenue) / historical.avgRevenue) * 100 : 0
    
    return {
      isImproving: revenueChange > 10,
      improvementPercent: Math.abs(revenueChange)
    }
  }

  private calculateEfficiency(analytics: any[]) {
    const recent = analytics.slice(0, 7)
    const avgCPA = recent.reduce((sum, a) => {
      return sum + (a.conversions > 0 ? a.spend / a.conversions : 0)
    }, 0) / recent.length

    const benchmarkCPA = 50
    const cpaIncrease = ((avgCPA - benchmarkCPA) / benchmarkCPA) * 100

    return {
      isInefficient: cpaIncrease > 20,
      cpaIncrease: Math.round(cpaIncrease),
      potentialSavings: Math.round(cpaIncrease * 0.6)
    }
  }

  private generateReportId(): string {
    return `report_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  private async getActiveCampaigns(tenantId: string) {
    return await prisma.campaign.findMany({
      where: { tenantId, status: 'RUNNING' }
    })
  }

  private async getRecentAnalytics(campaignId: string, days: number) {
    return await prisma.analytics.findMany({
      where: { campaignId },
      orderBy: { createdAt: 'desc' },
      take: days
    })
  }

  private async calculateBaseline(campaignId: string, days: number) {
    const analytics = await prisma.analytics.findMany({
      where: { campaignId },
      orderBy: { createdAt: 'desc' },
      take: days
    })

    return {
      avgRevenue: analytics.reduce((sum: number, a: any) => sum + a.revenue, 0) / analytics.length,
      avgConversions: analytics.reduce((sum: number, a: any) => sum + a.conversions, 0) / analytics.length,
      avgSpend: analytics.reduce((sum: number, a: any) => sum + a.spend, 0) / analytics.length,
      stdDevRevenue: this.calculateStandardDeviation(analytics.map((a: any) => a.revenue))
    }
  }

  private detectCampaignAnomalies(campaign: any, recent: any[], baseline: any) {
    const anomalies = []
    const recentAvg = recent.reduce((sum, a) => sum + a.revenue, 0) / recent.length
    
    const deviation = Math.abs(recentAvg - baseline.avgRevenue) / baseline.stdDevRevenue
    
    if (deviation > 2) {
      anomalies.push({
        campaignId: campaign.id,
        campaignName: campaign.name,
        metric: 'revenue',
        currentValue: recentAvg,
        expectedValue: baseline.avgRevenue,
        deviation: Math.round(deviation * 100) / 100,
        severity: deviation > 3 ? 'high' as const : 'medium' as const,
        detectedAt: new Date().toISOString(),
        possibleCauses: [
          'Market conditions change',
          'Creative fatigue',
          'Targeting drift'
        ]
      })
    }

    return anomalies
  }

  private calculateStandardDeviation(values: number[]): number {
    const mean = values.reduce((sum, val) => sum + val, 0) / values.length
    const variance = values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length
    return Math.sqrt(variance)
  }
}

// Export singleton instance
export const analyticsService = new AdvancedAnalyticsService()