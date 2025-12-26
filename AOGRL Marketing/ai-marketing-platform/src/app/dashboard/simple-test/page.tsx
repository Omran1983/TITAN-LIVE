'use client';

import { useState, useEffect } from 'react';

export default function SimpleDashboardTest() {
  const [creatives, setCreatives] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCreatives = async () => {
      try {
        setLoading(true);
        const response = await fetch('/api/creatives');
        const data = await response.json();
        
        if (response.ok) {
          setCreatives(data.creatives || []);
        } else {
          setError(data.error || 'Failed to fetch creatives');
        }
      } catch (err) {
        setError(`Network error: ${(err as Error).message}`);
      } finally {
        setLoading(false);
      }
    };

    fetchCreatives();
  }, []);

  if (loading) {
    return (
      <div className="p-8">
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mr-3"></div>
          <span>Loading content...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          <strong>Error:</strong> {error}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Dashboard Test</h1>
      
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">AI Generated Content</h2>
        <p className="text-gray-600 mb-4">Found {creatives.length} creative items</p>
        
        {creatives.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded">
            <p className="text-gray-500">No AI-generated content found.</p>
            <p className="text-sm text-gray-400 mt-2">Create some content using the generation tools.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {creatives.map((creative) => (
              <div key={creative.id} className="border border-gray-200 rounded-lg overflow-hidden">
                <div className="p-4 bg-gray-50 border-b">
                  <div className="flex justify-between items-start">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {creative.type}
                    </span>
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      {creative.status}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 mt-2">
                    {new Date(creative.createdAt).toLocaleDateString()}
                  </p>
                </div>
                
                <div className="p-4">
                  {creative.type === 'IMAGE' ? (
                    <div className="bg-gray-100 h-32 flex items-center justify-center rounded">
                      <span className="text-gray-500 text-sm">Image Content</span>
                    </div>
                  ) : creative.type === 'COPY' ? (
                    <p className="text-sm text-gray-700 line-clamp-3">
                      {typeof creative.content === 'string' 
                        ? creative.content 
                        : creative.content?.text || creative.content?.description || 'Copy content'}
                    </p>
                  ) : (
                    <p className="text-sm text-gray-500">
                      {creative.type} content
                    </p>
                  )}
                  
                  {creative.prompt && (
                    <p className="text-xs text-gray-500 mt-3 line-clamp-2">
                      Prompt: {creative.prompt}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}