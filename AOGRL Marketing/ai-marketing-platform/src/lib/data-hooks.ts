import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { 
  campaignService, 
  productService, 
  creativeService, 
  analyticsService, 
  queueService, 
  auditService, 
  clientService, 
  budgetService,
  userService
} from './api-service'
import { toast } from 'react-hot-toast'

// Campaign Hooks
export const useCampaigns = () => {
  return useQuery({
    queryKey: ['campaigns'],
    queryFn: () => campaignService.getAll(),
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export const useCampaign = (id: string) => {
  return useQuery({
    queryKey: ['campaigns', id],
    queryFn: () => campaignService.getById(id),
    enabled: !!id,
    retry: 1,
  })
}

export const useCreateCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => campaignService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign created successfully! 🚀')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to create campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useUpdateCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      campaignService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useDeleteCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign deleted successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to delete campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useStartCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignService.start(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign started successfully! 🎯')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to start campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const usePauseCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignService.pause(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign paused')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to pause campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useStopCampaign = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => campaignService.stop(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['campaigns'] })
      toast.success('Campaign stopped successfully! 🛑')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to stop campaign'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

// Product Hooks
export const useProducts = () => {
  return useQuery({
    queryKey: ['products'],
    queryFn: () => productService.getAll(),
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export const useCreateProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => productService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product created successfully! 📦')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to create product'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useUpdateProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      productService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update product'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useDeleteProduct = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => productService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product deleted successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to delete product'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

// Creative Hooks
export const useCreatives = () => {
  return useQuery({
    queryKey: ['creatives'],
    queryFn: () => creativeService.getAll(),
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export const useGenerateCreative = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => creativeService.generate(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['creatives'] })
      toast.success('Creative generation started! 🎨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to generate creative'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

// Analytics Hooks
export const useDashboardAnalytics = () => {
  return useQuery({
    queryKey: ['analytics', 'dashboard'],
    queryFn: () => analyticsService.getDashboard(),
    retry: 1,
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useAnalyticsOverview = (params?: any) => {
  return useQuery({
    queryKey: ['analytics', 'overview', params],
    queryFn: () => analyticsService.getOverview(params),
    retry: 1,
    enabled: !!params,
  })
}

// Advanced Analytics Hooks
export const useGenerateAnalyticsReport = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => analyticsService.generateReport(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['analytics'] })
      toast.success('📊 Analytics report generated!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Report generation failed'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useAnalyticsAnomalies = () => {
  return useQuery({
    queryKey: ['analytics-anomalies'],
    queryFn: () => analyticsService.getAnomalies(),
    retry: 1,
    refetchInterval: 300000, // Refresh every 5 minutes
  })
}

export const useAttributionAnalysis = (campaignId: string) => {
  return useQuery({
    queryKey: ['analytics-attribution', campaignId],
    queryFn: () => analyticsService.getAttribution(campaignId),
    enabled: !!campaignId,
    retry: 1,
  })
}

export const useMarketIntelligence = (industry?: string) => {
  return useQuery({
    queryKey: ['market-intelligence', industry],
    queryFn: () => analyticsService.getMarketIntelligence(industry),
    retry: 1,
    staleTime: 3600000, // 1 hour
  })
}

// Queue Hooks
export const useQueueJobs = (filters?: any) => {
  return useQuery({
    queryKey: ['queue', 'jobs', filters],
    queryFn: () => queueService.getJobs(filters),
    retry: 1,
    refetchInterval: 5000, // Refresh every 5 seconds for real-time updates
  })
}

export const useQueueStats = () => {
  return useQuery({
    queryKey: ['queue', 'stats'],
    queryFn: () => queueService.getStats(),
    retry: 1,
    refetchInterval: 10000, // Refresh every 10 seconds
  })
}

export const useQueueMetrics = (timeframe: string = '24h') => {
  return useQuery({
    queryKey: ['queue', 'metrics', timeframe],
    queryFn: () => queueService.getMetrics(timeframe),
    retry: 1,
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useQueueWorkers = () => {
  return useQuery({
    queryKey: ['queue', 'workers'],
    queryFn: () => queueService.getWorkers(),
    retry: 1,
    refetchInterval: 15000, // Refresh every 15 seconds
  })
}

export const useJobDetails = (jobId: string) => {
  return useQuery({
    queryKey: ['queue', 'job', jobId],
    queryFn: () => queueService.getJob(jobId),
    enabled: !!jobId,
    retry: 1,
    refetchInterval: 2000, // Refresh every 2 seconds for active job monitoring
  })
}

export const useCreateJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => queueService.createJob(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('🚀 Job created and queued successfully!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Failed to create job'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const usePauseJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueService.pauseJob(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job paused')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to pause job'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useResumeJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueService.resumeJob(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job resumed')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to resume job'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useRetryJob = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => queueService.retryJob(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job retried')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to retry job'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

// Audit Hooks
export const useAuditLogs = (params?: any) => {
  return useQuery({
    queryKey: ['audit', params],
    queryFn: () => auditService.getLogs(params),
    retry: 1,
  })
}

// Client Hooks (for your marketing agency)
export const useClients = () => {
  return useQuery({
    queryKey: ['clients'],
    queryFn: () => clientService.getAll(),
    retry: 1,
  })
}

export const useCreateClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => clientService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client added successfully! 🎉')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to add client'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useUpdateClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => 
      clientService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client updated successfully! ✨')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update client'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useDeleteClient = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (id: string) => clientService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] })
      toast.success('Client removed successfully')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to remove client'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

// Budget Optimization Hooks
export const useBudgetOptimization = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => budgetService.optimize(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['budget-optimization'] })
      toast.success('🎯 Budget optimization completed!')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.error || error.message || 'Optimization failed'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}

export const useBudgetAlerts = () => {
  return useQuery({
    queryKey: ['budget-alerts'],
    queryFn: () => budgetService.getAlerts(),
    retry: 1,
    refetchInterval: 30000, // Refresh every 30 seconds
  })
}

export const useBudgetMonitoring = () => {
  return useQuery({
    queryKey: ['budget-monitoring'],
    queryFn: () => budgetService.getMonitoring(),
    retry: 1,
    refetchInterval: 60000, // Refresh every minute
  })
}

export const useBudgetForecast = (campaignId: string, days: number = 30) => {
  return useQuery({
    queryKey: ['budget-forecast', campaignId, days],
    queryFn: () => budgetService.getForecast(campaignId, days),
    enabled: !!campaignId,
    retry: 1,
  })
}

// User Preferences Hooks
export const useUserPreferences = () => {
  return useQuery({
    queryKey: ['user-preferences'],
    queryFn: () => userService.getPreferences(),
    retry: 1,
  })
}

export const useUpdateUserPreferences = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: (data: any) => userService.updatePreferences(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user-preferences'] })
      toast.success('Preferences updated successfully! ⚙️')
    },
    onError: (error: any) => {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to update preferences'
      if (errorMessage && errorMessage !== '{}' && errorMessage !== '""') {
        toast.error(`Error: ${errorMessage}`)
      }
    },
  })
}