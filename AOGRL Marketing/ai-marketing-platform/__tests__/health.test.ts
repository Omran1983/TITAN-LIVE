/**
 * @jest-environment node
 */

import { createMocks } from 'node-mocks-http';
import { GET } from '@/app/api/health/route';

describe('/api/health', () => {
  it('should return ok status', async () => {
    const { req, res } = createMocks({
      method: 'GET',
    });

    const response = await GET();
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.ok).toBe(true);
    expect(data.database).toBe('connected');
    expect(data.stats).toBeDefined();
    expect(data.timestamp).toBeDefined();
  });
});