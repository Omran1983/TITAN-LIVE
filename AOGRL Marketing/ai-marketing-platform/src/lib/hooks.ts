import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { campaignApi, productApi, creativeApi, analyticsApi, queueApi, auditApi, clientApi, budgetApi } from './api'
import { toast } from 'react-hot-toast'

// Campaign Hooks
export const useCampaigns = () => {
  return useQuery({
    queryKey: ['campaigns'],
    queryFn: () => campaignApi.getAll().then(res => res.data),
  })
}

export const useCampaign = (id: string) => {
  return useQuery({
    queryKey: ['campaigns', id],
    queryFn: () => campaignApi.getById(id).then(res => res.data),
    enabled: !!id,
  })
}

export const useCreateCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => campaignApi.create(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign created successfully! 🚀')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to create campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useUpdateCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      campaignApi.update(id, data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useDeleteCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignApi.delete(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign deleted successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to delete campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useStartCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignApi.start(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign started successfully! 🎯')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to start campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const usePauseCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignApi.pause(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign paused')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to pause campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useStopCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignApi.stop(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign stopped successfully! 🛑')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to stop campaign'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// Product Hooks
export const useProducts = () => {
  return useQuery({
    queryKey: ['products'],
    queryFn: () => productApi.getAll().then(res => res.data),
  })
}

export const useCreateProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => productApi.create(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product created successfully! 📦')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to create product'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useUpdateProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      productApi.update(id, data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update product'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useDeleteProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => productApi.delete(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product deleted successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to delete product'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// Creative Hooks
export const useCreatives = () => {
  return useQuery({
    queryKey: ['creatives'],
    queryFn: () => creativeApi.getAll().then(res => res.data),
  })
}

export const useGenerateCreative = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => creativeApi.generate(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['creatives'] })
      toast.success('Creative generation started! 🎨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to generate creative'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// Analytics Hooks
export const useDashboardAnalytics = () => {
  return useQuery({
    queryKey: ['analytics', 'dashboard'],
    queryFn: () => analyticsApi.getDashboard().then(res => res.data),
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useAnalyticsOverview = (params?: any) => {
  return useQuery({
    queryKey: ['analytics', 'overview', params],
    queryFn: () => analyticsApi.getOverview(params).then(res => res.data),
  })
}

// Advanced Analytics Hooks
export const useGenerateAnalyticsReport = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => analyticsApi.generateReport(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['analytics'] })
      toast.success('📊 Analytics report generated!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Report generation failed'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useAnalyticsAnomalies = () => {
  return useQuery({
    queryKey: ['analytics-anomalies'],
    queryFn: () => analyticsApi.getAnomalies().then(res => res.data),
    refetchInterval: 300000, // Refresh every 5 minutes
  })
}

export const useAttributionAnalysis = (campaignId: string) => {
  return useQuery({
    queryKey: ['analytics-attribution', campaignId],
    queryFn: () => analyticsApi.getAttribution(campaignId).then(res => res.data),
    enabled: !!campaignId,
  })
}

export const useMarketIntelligence = (industry?: string) => {
  return useQuery({
    queryKey: ['market-intelligence', industry],
    queryFn: () => analyticsApi.getMarketIntelligence(industry).then(res => res.data),
    staleTime: 3600000, // 1 hour
  })
}

// Queue Hooks
export const useQueueJobs = (filters?: any) => {
  return useQuery({
    queryKey: ['queue', 'jobs', filters],
    queryFn: () => queueApi.getJobs(filters).then(res => res.data),
    refetchInterval: 5000, // Refresh every 5 seconds for real-time updates
  })
}

export const useQueueStats = () => {
  return useQuery({
    queryKey: ['queue', 'stats'],
    queryFn: () => queueApi.getStats().then(res => res.data),
    refetchInterval: 10000, // Refresh every 10 seconds
  })
}

export const useQueueMetrics = (timeframe: string = '24h') => {
  return useQuery({
    queryKey: ['queue', 'metrics', timeframe],
    queryFn: () => queueApi.getMetrics(timeframe).then(res => res.data),
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useQueueWorkers = () => {
  return useQuery({
    queryKey: ['queue', 'workers'],
    queryFn: () => queueApi.getWorkers().then(res => res.data),
    refetchInterval: 15000, // Refresh every 15 seconds
  })
}

export const useJobDetails = (jobId: string) => {
  return useQuery({
    queryKey: ['queue', 'job', jobId],
    queryFn: () => queueApi.getJob(jobId).then(res => res.data),
    enabled: !!jobId,
    refetchInterval: 2000, // Refresh every 2 seconds for active job monitoring
  })
}

export const useCreateJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => queueApi.createJob(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('🚀 Job created and queued successfully!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Failed to create job'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const usePauseJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueApi.pauseJob(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job paused')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to pause job'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useResumeJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueApi.resumeJob(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job resumed')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to resume job'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useRetryJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueApi.retryJob(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job retried')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to retry job'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// Audit Hooks
export const useAuditLogs = (params?: any) => {
  return useQuery({
    queryKey: ['audit', params],
    queryFn: () => auditApi.getLogs(params).then(res => res.data),
  })
}

// Client Hooks (for your marketing agency)
export const useClients = () => {
  return useQuery({
    queryKey: ['clients'],
    queryFn: () => clientApi.getAll().then(res => res.data),
  })
}

export const useCreateClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => clientApi.create(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client added successfully! 🎉')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to add client'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useUpdateClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      clientApi.update(id, data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update client'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// Budget Optimization Hooks
export const useBudgetOptimization = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => budgetApi.optimize(data).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['budget-optimization'] })
      toast.success('🎯 Budget optimization completed!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Optimization failed'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

export const useBudgetAlerts = () => {
  return useQuery({
    queryKey: ['budget-alerts'],
    queryFn: () => budgetApi.getAlerts().then(res => res.data),
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useBudgetMonitoring = () => {
  return useQuery({
    queryKey: ['budget-monitoring'],
    queryFn: () => budgetApi.getMonitoring().then(res => res.data),
    refetchInterval: 60000, // Refresh every minute
  })
}

export const useBudgetForecast = (campaignId: string, days: number = 30) => {
  return useQuery({
    queryKey: ['budget-forecast', campaignId, days],
    queryFn: () => budgetApi.getForecast(campaignId, days).then(res => res.data),
    enabled: !!campaignId,
  })
}

export const useDeleteClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => clientApi.delete(id).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client removed successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to remove client'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}

// User Preferences Hooks
export const useUserPreferences = () => {
  return useQuery({
    queryKey: ['user-preferences'],
    queryFn: () => import('./api').then(({ userApi }) => userApi.getPreferences().then(res => res.data))
  })
}

export const useUpdateUserPreferences = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => import('./api').then(({ userApi }) => userApi.updatePreferences(data).then(res => res.data)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user-preferences'] })
      toast.success('Preferences updated successfully! ⚙️')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update preferences'
      // Only show toast for significant errors
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(errorMessage)
      }
    },
  })
}