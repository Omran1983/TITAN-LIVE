// AI-Powered Budget Optimization Service
import { prisma } from './prisma'

export interface BudgetOptimizationRequest {
  campaignIds?: string[]
  totalBudget: number
  currency: string
  timeframe: 'daily' | 'weekly' | 'monthly'
  objectives: {
    primary: 'conversions' | 'reach' | 'engagement' | 'revenue'
    secondary?: 'cpa' | 'roas' | 'ctr' | 'brand_awareness'
  }
  constraints?: {
    minBudgetPerCampaign?: number
    maxBudgetPerCampaign?: number
    excludedCampaigns?: string[]
  }
}

export interface BudgetRecommendation {
  campaignId: string
  campaignName: string
  currentBudget: number
  recommendedBudget: number
  budgetChange: number
  budgetChangePercent: number
  confidence: number
  reasoning: string[]
  predictedMetrics: {
    expectedConversions: number
    expectedRevenue: number
    expectedROAS: number
    expectedCPA: number
  }
  riskLevel: 'low' | 'medium' | 'high'
}

export interface BudgetOptimizationResult {
  recommendations: BudgetRecommendation[]
  totalOptimizedBudget: number
  budgetUtilization: number
  expectedPerformanceImprovement: {
    conversions: number
    revenue: number
    roas: number
    efficiency: number
  }
  riskAnalysis: {
    overallRisk: 'low' | 'medium' | 'high'
    highRiskCampaigns: string[]
    recommendations: string[]
  }
  timeframePredictions: {
    [key: string]: {
      date: string
      budget: number
      expectedMetrics: any
    }
  }
}

export class BudgetOptimizer {
  // Main optimization engine
  async optimizeBudget(request: BudgetOptimizationRequest, tenantId: string): Promise<BudgetOptimizationResult> {
    // Fetch campaign data with analytics
    const campaigns = await this.getCampaignData(request.campaignIds, tenantId)
    
    // Calculate performance metrics for each campaign
    const campaignMetrics = await this.calculateCampaignMetrics(campaigns)
    
    // Apply AI-powered optimization algorithms
    const recommendations = await this.generateRecommendations(
      campaignMetrics,
      request
    )
    
    // Calculate overall optimization results
    const optimizationResult = this.calculateOptimizationResult(
      recommendations,
      request
    )
    
    return optimizationResult
  }

  // Real-time budget monitoring and alerts
  async monitorBudgets(tenantId: string): Promise<{
    alerts: Array<{
      type: 'overspend' | 'underspend' | 'performance_drop' | 'opportunity'
      campaignId: string
      campaignName: string
      severity: 'low' | 'medium' | 'high'
      message: string
      recommendedAction: string
    }>
    summary: {
      totalSpend: number
      totalBudget: number
      utilization: number
      activeAlerts: number
    }
  }> {
    const campaigns = await this.getActiveCampaigns(tenantId)
    const alerts = []
    let totalSpend = 0
    let totalBudget = 0

    for (const campaign of campaigns) {
      const analytics = await this.getCampaignAnalytics(campaign.id)
      const spent = analytics.reduce((sum: number, a: any) => sum + a.spend, 0)
      const budget = campaign.budget
      
      totalSpend += spent
      totalBudget += budget
      
      // Check for overspend
      if (spent > budget * 0.9) {
        alerts.push({
          type: 'overspend' as const,
          campaignId: campaign.id,
          campaignName: campaign.name,
          severity: spent > budget ? 'high' as const : 'medium' as const,
          message: `Campaign is ${spent > budget ? 'over' : 'approaching'} budget limit`,
          recommendedAction: spent > budget ? 'Pause campaign or increase budget' : 'Monitor closely'
        })
      }
      
      // Check for underspend
      if (spent < budget * 0.5 && this.isHalfwayThroughPeriod(campaign)) {
        alerts.push({
          type: 'underspend' as const,
          campaignId: campaign.id,
          campaignName: campaign.name,
          severity: 'medium' as const,
          message: 'Campaign is significantly underspending',
          recommendedAction: 'Increase bids or expand targeting'
        })
      }
      
      // Check for performance drops
      const performanceTrend = await this.getPerformanceTrend(campaign.id)
      if (performanceTrend.isDecreasing && performanceTrend.severity > 0.2) {
        alerts.push({
          type: 'performance_drop' as const,
          campaignId: campaign.id,
          campaignName: campaign.name,
          severity: performanceTrend.severity > 0.5 ? 'high' as const : 'medium' as const,
          message: 'Campaign performance is declining',
          recommendedAction: 'Review targeting, creative, or bid strategy'
        })
      }
    }

    return {
      alerts,
      summary: {
        totalSpend,
        totalBudget,
        utilization: totalBudget > 0 ? (totalSpend / totalBudget) * 100 : 0,
        activeAlerts: alerts.length
      }
    }
  }

  // Predictive budget forecasting
  async forecastBudgetNeeds(
    campaignId: string, 
    days: number = 30
  ): Promise<{
    dailyForecasts: Array<{
      date: string
      predictedSpend: number
      predictedConversions: number
      predictedRevenue: number
      confidence: number
    }>
    summary: {
      totalPredictedSpend: number
      totalPredictedRevenue: number
      predictedROAS: number
      budgetRecommendation: number
    }
  }> {
    const historicalData = await this.getHistoricalCampaignData(campaignId, 90)
    const seasonalFactors = this.calculateSeasonalFactors(historicalData)
    const trendFactors = this.calculateTrendFactors(historicalData)
    
    const dailyForecasts = []
    let totalPredictedSpend = 0
    let totalPredictedRevenue = 0
    
    for (let i = 1; i <= days; i++) {
      const baseSpend = this.calculateBaseSpend(historicalData)
      const seasonalAdjustment = seasonalFactors[new Date(Date.now() + i * 24 * 60 * 60 * 1000).getDay()]
      const trendAdjustment = trendFactors.daily
      
      const predictedSpend = baseSpend * seasonalAdjustment * trendAdjustment
      const predictedConversions = predictedSpend * this.getAverageConversionRate(historicalData)
      const predictedRevenue = predictedConversions * this.getAverageOrderValue(historicalData)
      
      totalPredictedSpend += predictedSpend
      totalPredictedRevenue += predictedRevenue
      
      dailyForecasts.push({
        date: new Date(Date.now() + i * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        predictedSpend,
        predictedConversions,
        predictedRevenue,
        confidence: this.calculateConfidence(historicalData)
      })
    }
    
    return {
      dailyForecasts,
      summary: {
        totalPredictedSpend,
        totalPredictedRevenue,
        predictedROAS: totalPredictedSpend > 0 ? totalPredictedRevenue / totalPredictedSpend : 0,
        budgetRecommendation: totalPredictedSpend * 1.1 // 10% buffer
      }
    }
  }

  // Private helper methods
  private async getCampaignData(campaignIds: string[] | undefined, tenantId: string) {
    const whereClause: any = { tenantId }
    if (campaignIds && campaignIds.length > 0) {
      whereClause.id = { in: campaignIds }
    }

    return await prisma.campaign.findMany({
      where: whereClause,
      include: {
        analytics: {
          orderBy: { createdAt: 'desc' },
          take: 30 // Last 30 data points
        },
        products: {
          include: {
            product: true
          }
        }
      }
    })
  }

  private async calculateCampaignMetrics(campaigns: any[]) {
    return campaigns.map(campaign => {
      const analytics = campaign.analytics
      const totalSpend = analytics.reduce((sum: number, a: any) => sum + a.spend, 0)
      const totalRevenue = analytics.reduce((sum: number, a: any) => sum + a.revenue, 0)
      const totalConversions = analytics.reduce((sum: number, a: any) => sum + a.conversions, 0)
      const totalImpressions = analytics.reduce((sum: number, a: any) => sum + a.impressions, 0)
      const totalClicks = analytics.reduce((sum: number, a: any) => sum + a.clicks, 0)

      return {
        campaignId: campaign.id,
        campaignName: campaign.name,
        currentBudget: campaign.budget,
        metrics: {
          spend: totalSpend,
          revenue: totalRevenue,
          conversions: totalConversions,
          impressions: totalImpressions,
          clicks: totalClicks,
          roas: totalSpend > 0 ? totalRevenue / totalSpend : 0,
          cpa: totalConversions > 0 ? totalSpend / totalConversions : 0,
          ctr: totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0,
          conversionRate: totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 0
        },
        performance: {
          trend: this.calculatePerformanceTrend(analytics),
          stability: this.calculateStability(analytics),
          efficiency: this.calculateEfficiency(analytics)
        }
      }
    })
  }

  private async generateRecommendations(
    campaignMetrics: any[],
    request: BudgetOptimizationRequest
  ): Promise<BudgetRecommendation[]> {
    const totalCurrentBudget = campaignMetrics.reduce((sum, c) => sum + c.currentBudget, 0)
    const budgetMultiplier = request.totalBudget / totalCurrentBudget

    return campaignMetrics.map(campaign => {
      const performanceScore = this.calculatePerformanceScore(campaign, request.objectives)
      const riskScore = this.calculateRiskScore(campaign)
      
      // AI-powered budget allocation based on performance and objectives
      let recommendedBudget = campaign.currentBudget * budgetMultiplier
      
      // Adjust based on performance
      if (performanceScore > 0.8) {
        recommendedBudget *= 1.2 // Increase budget for high performers
      } else if (performanceScore < 0.4) {
        recommendedBudget *= 0.8 // Decrease budget for poor performers
      }
      
      // Apply constraints
      if (request.constraints?.minBudgetPerCampaign) {
        recommendedBudget = Math.max(recommendedBudget, request.constraints.minBudgetPerCampaign)
      }
      if (request.constraints?.maxBudgetPerCampaign) {
        recommendedBudget = Math.min(recommendedBudget, request.constraints.maxBudgetPerCampaign)
      }

      const budgetChange = recommendedBudget - campaign.currentBudget
      const budgetChangePercent = campaign.currentBudget > 0 ? (budgetChange / campaign.currentBudget) * 100 : 0

      return {
        campaignId: campaign.campaignId,
        campaignName: campaign.campaignName,
        currentBudget: campaign.currentBudget,
        recommendedBudget: Math.round(recommendedBudget * 100) / 100,
        budgetChange: Math.round(budgetChange * 100) / 100,
        budgetChangePercent: Math.round(budgetChangePercent * 100) / 100,
        confidence: this.calculateConfidence(campaign),
        reasoning: this.generateReasoning(campaign, performanceScore, riskScore),
        predictedMetrics: this.predictMetrics(campaign, recommendedBudget),
        riskLevel: riskScore > 0.7 ? 'high' : riskScore > 0.4 ? 'medium' : 'low'
      }
    })
  }

  private calculateOptimizationResult(
    recommendations: BudgetRecommendation[],
    request: BudgetOptimizationRequest
  ): BudgetOptimizationResult {
    const totalOptimizedBudget = recommendations.reduce((sum, r) => sum + r.recommendedBudget, 0)
    const budgetUtilization = (totalOptimizedBudget / request.totalBudget) * 100

    const expectedPerformanceImprovement = {
      conversions: recommendations.reduce((sum, r) => sum + r.predictedMetrics.expectedConversions, 0),
      revenue: recommendations.reduce((sum, r) => sum + r.predictedMetrics.expectedRevenue, 0),
      roas: 0,
      efficiency: 15 // Average efficiency improvement
    }
    
    expectedPerformanceImprovement.roas = expectedPerformanceImprovement.revenue / totalOptimizedBudget

    const highRiskCampaigns = recommendations
      .filter(r => r.riskLevel === 'high')
      .map(r => r.campaignId)

    return {
      recommendations,
      totalOptimizedBudget: Math.round(totalOptimizedBudget * 100) / 100,
      budgetUtilization: Math.round(budgetUtilization * 100) / 100,
      expectedPerformanceImprovement,
      riskAnalysis: {
        overallRisk: highRiskCampaigns.length > recommendations.length * 0.3 ? 'high' : 
                    highRiskCampaigns.length > 0 ? 'medium' : 'low',
        highRiskCampaigns,
        recommendations: this.generateRiskRecommendations(recommendations)
      },
      timeframePredictions: this.generateTimeframePredictions(recommendations, request.timeframe)
    }
  }

  // Additional helper methods
  private calculatePerformanceScore(campaign: any, objectives: any): number {
    const weights = {
      conversions: objectives.primary === 'conversions' ? 0.4 : 0.2,
      reach: objectives.primary === 'reach' ? 0.4 : 0.2,
      engagement: objectives.primary === 'engagement' ? 0.4 : 0.2,
      revenue: objectives.primary === 'revenue' ? 0.4 : 0.2
    }

    // Normalize metrics and calculate weighted score
    const normalizedROAS = Math.min(campaign.metrics.roas / 3, 1) // Cap at 3x ROAS
    const normalizedCTR = Math.min(campaign.metrics.ctr / 5, 1) // Cap at 5% CTR
    const normalizedConversionRate = Math.min(campaign.metrics.conversionRate / 10, 1) // Cap at 10%

    return (normalizedROAS * weights.revenue) + 
           (normalizedCTR * weights.engagement) + 
           (normalizedConversionRate * weights.conversions) +
           (campaign.performance.efficiency * weights.reach)
  }

  private calculateRiskScore(campaign: any): number {
    const stability = campaign.performance.stability
    const trend = campaign.performance.trend
    const efficiency = campaign.performance.efficiency

    // Higher risk for unstable, declining, or inefficient campaigns
    return (1 - stability) * 0.4 + (trend < 0 ? Math.abs(trend) : 0) * 0.3 + (1 - efficiency) * 0.3
  }

  private calculatePerformanceTrend(analytics: any[]): number {
    if (analytics.length < 7) return 0

    const recent = analytics.slice(0, 7)
    const older = analytics.slice(7, 14)

    const recentAvg = recent.reduce((sum, a) => sum + a.revenue, 0) / recent.length
    const olderAvg = older.reduce((sum, a) => sum + a.revenue, 0) / older.length

    return olderAvg > 0 ? (recentAvg - olderAvg) / olderAvg : 0
  }

  private calculateStability(analytics: any[]): number {
    if (analytics.length < 5) return 0.5

    const revenues = analytics.map(a => a.revenue)
    const mean = revenues.reduce((sum, r) => sum + r, 0) / revenues.length
    const variance = revenues.reduce((sum, r) => sum + Math.pow(r - mean, 2), 0) / revenues.length
    const standardDeviation = Math.sqrt(variance)
    const coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1

    return Math.max(0, 1 - coefficientOfVariation)
  }

  private calculateEfficiency(analytics: any[]): number {
    if (analytics.length === 0) return 0.5

    const avgROAS = analytics.reduce((sum, a) => sum + (a.revenue / (a.spend || 1)), 0) / analytics.length
    return Math.min(avgROAS / 2, 1) // Normalize to 0-1 scale
  }

  private calculateConfidence(campaign: any): number {
    const dataPoints = campaign.analytics?.length || 0
    const stability = campaign.performance?.stability || 0.5
    const consistency = campaign.performance?.efficiency || 0.5

    // Higher confidence with more data points and stable performance
    const dataConfidence = Math.min(dataPoints / 30, 1)
    return (dataConfidence * 0.4 + stability * 0.3 + consistency * 0.3) * 100
  }

  private generateReasoning(campaign: any, performanceScore: number, riskScore: number): string[] {
    const reasons = []

    if (performanceScore > 0.8) {
      reasons.push("High-performing campaign with strong ROI")
    } else if (performanceScore < 0.4) {
      reasons.push("Underperforming campaign requiring optimization")
    }

    if (riskScore > 0.7) {
      reasons.push("High risk due to unstable performance")
    } else if (riskScore < 0.3) {
      reasons.push("Low risk with consistent performance")
    }

    if (campaign.metrics.roas > 2) {
      reasons.push("Excellent return on ad spend")
    }

    if (campaign.performance.trend > 0.1) {
      reasons.push("Positive performance trend")
    } else if (campaign.performance.trend < -0.1) {
      reasons.push("Declining performance trend")
    }

    return reasons
  }

  private predictMetrics(campaign: any, newBudget: number): any {
    const budgetRatio = newBudget / (campaign.currentBudget || 1)
    const efficiency = campaign.performance?.efficiency || 0.5

    return {
      expectedConversions: Math.round((campaign.metrics.conversions || 0) * budgetRatio * efficiency * 100) / 100,
      expectedRevenue: Math.round((campaign.metrics.revenue || 0) * budgetRatio * efficiency * 100) / 100,
      expectedROAS: campaign.metrics.roas * efficiency,
      expectedCPA: campaign.metrics.cpa / efficiency
    }
  }

  private generateRiskRecommendations(recommendations: BudgetRecommendation[]): string[] {
    const recs = []
    const highRiskCount = recommendations.filter(r => r.riskLevel === 'high').length

    if (highRiskCount > 0) {
      recs.push(`Monitor ${highRiskCount} high-risk campaigns closely`)
    }

    const bigIncreaseCampaigns = recommendations.filter(r => r.budgetChangePercent > 50).length
    if (bigIncreaseCampaigns > 0) {
      recs.push(`${bigIncreaseCampaigns} campaigns have significant budget increases - monitor performance`)
    }

    recs.push("Implement daily budget monitoring")
    recs.push("Set up automated alerts for budget overspend")

    return recs
  }

  private generateTimeframePredictions(recommendations: BudgetRecommendation[], timeframe: string): any {
    const predictions: any = {}
    const days = timeframe === 'daily' ? 7 : timeframe === 'weekly' ? 4 : 12

    for (let i = 1; i <= days; i++) {
      const date = new Date()
      if (timeframe === 'daily') {
        date.setDate(date.getDate() + i)
      } else if (timeframe === 'weekly') {
        date.setDate(date.getDate() + (i * 7))
      } else {
        date.setMonth(date.getMonth() + i)
      }

      predictions[`period_${i}`] = {
        date: date.toISOString().split('T')[0],
        budget: recommendations.reduce((sum, r) => sum + r.recommendedBudget, 0),
        expectedMetrics: {
          conversions: recommendations.reduce((sum, r) => sum + r.predictedMetrics.expectedConversions, 0),
          revenue: recommendations.reduce((sum, r) => sum + r.predictedMetrics.expectedRevenue, 0)
        }
      }
    }

    return predictions
  }

  // Helper methods for monitoring
  private async getActiveCampaigns(tenantId: string) {
    return await prisma.campaign.findMany({
      where: {
        tenantId,
        status: 'RUNNING'
      }
    })
  }

  private async getCampaignAnalytics(campaignId: string) {
    return await prisma.analytics.findMany({
      where: { campaignId },
      orderBy: { createdAt: 'desc' },
      take: 30
    })
  }

  private isHalfwayThroughPeriod(campaign: any): boolean {
    if (!campaign.startDate || !campaign.endDate) return false
    
    const now = new Date()
    const start = new Date(campaign.startDate)
    const end = new Date(campaign.endDate)
    const total = end.getTime() - start.getTime()
    const elapsed = now.getTime() - start.getTime()
    
    return elapsed / total > 0.5
  }

  private async getPerformanceTrend(campaignId: string): Promise<{ isDecreasing: boolean; severity: number }> {
    const analytics = await prisma.analytics.findMany({
      where: { campaignId },
      orderBy: { createdAt: 'desc' },
      take: 14
    })

    if (analytics.length < 7) return { isDecreasing: false, severity: 0 }

    const recent = analytics.slice(0, 7)
    const older = analytics.slice(7, 14)

    const recentAvg = recent.reduce((sum: number, a: any) => sum + a.revenue, 0) / recent.length
    const olderAvg = older.reduce((sum: number, a: any) => sum + a.revenue, 0) / older.length

    const decrease = olderAvg - recentAvg
    const severity = olderAvg > 0 ? decrease / olderAvg : 0

    return {
      isDecreasing: decrease > 0,
      severity: Math.max(0, severity)
    }
  }

  private async getHistoricalCampaignData(campaignId: string, days: number) {
    const endDate = new Date()
    const startDate = new Date(endDate.getTime() - (days * 24 * 60 * 60 * 1000))

    return await prisma.analytics.findMany({
      where: {
        campaignId,
        createdAt: {
          gte: startDate,
          lte: endDate
        }
      },
      orderBy: { createdAt: 'asc' }
    })
  }

  private calculateSeasonalFactors(historicalData: any[]): number[] {
    // Calculate day-of-week seasonal factors
    const dayFactors = new Array(7).fill(1)
    
    if (historicalData.length > 21) { // Need at least 3 weeks of data
      const dayTotals = new Array(7).fill(0)
      const dayCounts = new Array(7).fill(0)

      historicalData.forEach(data => {
        const day = new Date(data.createdAt).getDay()
        dayTotals[day] += data.spend
        dayCounts[day]++
      })

      const overallAvg = dayTotals.reduce((sum, total, i) => sum + (total / dayCounts[i]), 0) / 7

      for (let i = 0; i < 7; i++) {
        if (dayCounts[i] > 0) {
          const dayAvg = dayTotals[i] / dayCounts[i]
          dayFactors[i] = overallAvg > 0 ? dayAvg / overallAvg : 1
        }
      }
    }

    return dayFactors
  }

  private calculateTrendFactors(historicalData: any[]): { daily: number; weekly: number } {
    if (historicalData.length < 14) return { daily: 1, weekly: 1 }

    const recent = historicalData.slice(-7)
    const older = historicalData.slice(-14, -7)

    const recentAvg = recent.reduce((sum, d) => sum + d.spend, 0) / recent.length
    const olderAvg = older.reduce((sum, d) => sum + d.spend, 0) / older.length

    const dailyTrend = olderAvg > 0 ? recentAvg / olderAvg : 1
    const weeklyTrend = Math.pow(dailyTrend, 7)

    return {
      daily: Math.max(0.5, Math.min(2, dailyTrend)), // Cap between 0.5x and 2x
      weekly: Math.max(0.3, Math.min(3, weeklyTrend))
    }
  }

  private calculateBaseSpend(historicalData: any[]): number {
    if (historicalData.length === 0) return 0
    return historicalData.reduce((sum, d) => sum + d.spend, 0) / historicalData.length
  }

  private getAverageConversionRate(historicalData: any[]): number {
    if (historicalData.length === 0) return 0.02 // Default 2%
    
    const totalClicks = historicalData.reduce((sum, d) => sum + d.clicks, 0)
    const totalConversions = historicalData.reduce((sum, d) => sum + d.conversions, 0)
    
    return totalClicks > 0 ? totalConversions / totalClicks : 0.02
  }

  private getAverageOrderValue(historicalData: any[]): number {
    if (historicalData.length === 0) return 50 // Default $50

    const totalRevenue = historicalData.reduce((sum, d) => sum + d.revenue, 0)
    const totalConversions = historicalData.reduce((sum, d) => sum + d.conversions, 0)

    return totalConversions > 0 ? totalRevenue / totalConversions : 50
  }
}

// Export singleton instance
export const budgetOptimizer = new BudgetOptimizer()