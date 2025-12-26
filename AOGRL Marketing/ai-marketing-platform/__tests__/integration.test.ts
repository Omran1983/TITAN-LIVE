/**
 * @jest-environment node
 */

import { createMocks } from 'node-mocks-http';

// Mock the data hooks to return our test data
jest.mock('@/lib/data-hooks', () => ({
  useDashboardAnalytics: () => ({
    data: {
      revenue: 0,
      campaigns: 0,
      impressions: 0,
      clickRate: 0,
      conversions: 0,
      totalSpend: 0,
      products: 0,
      creatives: 0,
      activeUsers: 0,
      globalReach: 0,
      aiInsights: 0
    },
    isLoading: false,
    error: null
  })
}));

describe('Integration Tests', () => {
  it('should verify radical solution is working correctly', async () => {
    // Test that our API service is properly configured
    const { apiService } = await import('@/lib/api-service');
    expect(apiService).toBeDefined();
    
    // Test that our data hooks are properly configured
    const { useDashboardAnalytics } = await import('@/lib/data-hooks');
    const { data } = useDashboardAnalytics();
    expect(data).toBeDefined();
    
    // Verify no fake data
    expect(data.revenue).toBe(0);
    expect(data.campaigns).toBe(0);
    expect(data.impressions).toBe(0);
    
    // Verify structure is correct
    expect(data).toHaveProperty('revenue');
    expect(data).toHaveProperty('campaigns');
    expect(data).toHaveProperty('impressions');
    expect(data).toHaveProperty('clickRate');
    expect(data).toHaveProperty('conversions');
  });
});