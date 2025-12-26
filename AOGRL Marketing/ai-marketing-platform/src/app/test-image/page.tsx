'use client';

import { useState, useEffect } from 'react';

export default function TestImagePage() {
  const [creatives, setCreatives] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCreative, setSelectedCreative] = useState<any>(null);

  useEffect(() => {
    const fetchCreatives = async () => {
      try {
        setLoading(true);
        setError(null);
        
        // Try both endpoints to see which one works
        const response1 = await fetch('/api/debug');
        const response2 = await fetch('/api/creatives');
        
        let data;
        if (response1.ok) {
          data = await response1.json();
          console.log('Debug API response:', data);
        } else if (response2.ok) {
          data = await response2.json();
          console.log('Creatives API response:', data);
        } else {
          throw new Error('Both APIs failed');
        }
        
        if (data.creatives && data.creatives.length > 0) {
          setCreatives(data.creatives);
          // Auto-select first image creative
          const firstImage = data.creatives.find((c: any) => c.type === 'IMAGE');
          if (firstImage) {
            setSelectedCreative(firstImage);
          }
        } else {
          setError('No creatives found');
        }
      } catch (err) {
        console.error('Error:', err);
        setError('Error fetching creatives: ' + (err as Error).message);
      } finally {
        setLoading(false);
      }
    };

    fetchCreatives();
  }, []);

  const getImageUrl = (content: any): string | null => {
    if (!content) return null;
    
    // Direct imageUrl property (from seed data)
    if (content.imageUrl) {
      console.log('Found direct imageUrl:', content.imageUrl);
      return content.imageUrl;
    }
    
    // Nested in result object (from AI generation)
    if (content.result?.url) {
      console.log('Found result.url:', content.result.url);
      return content.result.url;
    }
    
    // In result object with image property
    if (content.result?.image) {
      console.log('Found result.image:', content.result.image);
      return content.result.image;
    }
    
    // Direct url property
    if (content.url) {
      console.log('Found direct url:', content.url);
      return content.url;
    }
    
    console.log('No image URL found in content:', content);
    return null;
  };

  const renderImage = (creative: any) => {
    const imageUrl = getImageUrl(creative.content);
    
    if (!imageUrl) {
      return (
        <div className="p-4 bg-red-50 rounded">
          <p className="text-red-700 font-bold">No Image URL Found</p>
          <p className="text-red-600 text-sm">Content structure:</p>
          <pre className="text-xs bg-white p-2 rounded mt-2 overflow-auto max-h-40">
            {JSON.stringify(creative.content, null, 2)}
          </pre>
        </div>
      );
    }

    const isDataUrl = imageUrl.startsWith('data:');
    
    return (
      <div>
        <div className="mb-2 p-2 bg-blue-50 rounded">
          <p className="text-sm"><strong>URL Type:</strong> {isDataUrl ? 'Data URL' : 'Regular URL'}</p>
          <p className="text-xs truncate">URL: {imageUrl}</p>
        </div>
        
        <div className="border-2 border-dashed border-gray-300 rounded p-2">
          <img 
            src={imageUrl} 
            alt="Creative Content" 
            className="max-w-full h-auto"
            style={{ 
              minHeight: '100px',
              minWidth: '100px',
              backgroundColor: '#f0f0f0'
            }}
            onError={(e) => {
              console.log('❌ Image failed to load:', imageUrl);
            }}
            onLoad={(e) => {
              console.log('✅ Image loaded successfully:', imageUrl);
            }}
          />
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-8">
        <div className="flex justify-center items-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <span className="ml-3">Loading creatives...</span>
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
      <h1 className="text-3xl font-bold mb-6">Image Display Test</h1>
      
      {creatives.length === 0 ? (
        <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
          No creatives found in database
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Creative List */}
          <div>
            <h2 className="text-xl font-semibold mb-4">Available Creatives ({creatives.length})</h2>
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {creatives.map((creative) => (
                <div 
                  key={creative.id}
                  className={`p-3 border rounded cursor-pointer hover:bg-gray-50 ${
                    selectedCreative?.id === creative.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200'
                  }`}
                  onClick={() => setSelectedCreative(creative)}
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {creative.type}
                      </span>
                      <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        {creative.status}
                      </span>
                    </div>
                    <span className="text-xs text-gray-500">
                      {new Date(creative.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1 truncate">
                    {creative.prompt || 'No prompt'}
                  </p>
                </div>
              ))}
            </div>
          </div>
          
          {/* Selected Creative Preview */}
          <div>
            <h2 className="text-xl font-semibold mb-4">Preview</h2>
            {selectedCreative ? (
              <div className="border border-gray-200 rounded-lg p-4">
                <div className="mb-4">
                  <h3 className="font-bold text-lg">{selectedCreative.type} Creative</h3>
                  <p className="text-sm text-gray-600">ID: {selectedCreative.id}</p>
                </div>
                
                {renderImage(selectedCreative)}
                
                {selectedCreative.prompt && (
                  <div className="mt-4 p-3 bg-gray-50 rounded">
                    <p className="font-medium text-sm">Prompt:</p>
                    <p className="text-sm">{selectedCreative.prompt}</p>
                  </div>
                )}
              </div>
            ) : (
              <div className="bg-gray-100 border border-gray-300 rounded-lg p-8 text-center">
                <p>Select a creative from the list to preview</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}