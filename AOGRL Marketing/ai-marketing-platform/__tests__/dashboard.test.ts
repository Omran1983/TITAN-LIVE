/**
 * @jest-environment node
 */

import { createMocks } from 'node-mocks-http';
import { GET } from '@/app/api/analytics/dashboard/route';

describe('/api/analytics/dashboard', () => {
  it('should return dashboard data with all zeros (no fake data)', async () => {
    const { req, res } = createMocks({
      method: 'GET',
    });

    const response = await GET(req);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
    expect(data.data).toBeDefined();
    
    // Verify all dashboard metrics are 0 (no fake data)
    expect(data.data.revenue).toBe(0);
    expect(data.data.campaigns).toBe(0);
    expect(data.data.impressions).toBe(0);
    expect(data.data.clickRate).toBe(0);
    expect(data.data.conversions).toBe(0);
    expect(data.data.totalSpend).toBe(0);
    expect(data.data.products).toBe(0);
    expect(data.data.creatives).toBe(0);
    expect(data.data.activeUsers).toBe(0);
    expect(data.data.globalReach).toBe(0);
    expect(data.data.aiInsights).toBe(0);
  });
});