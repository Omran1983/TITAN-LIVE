'use client';

import { useState, useEffect } from 'react';

export default function SimpleTestPage() {
  const [status, setStatus] = useState('Checking...');
  const [apiStatus, setApiStatus] = useState('Unknown');
  const [dbStatus, setDbStatus] = useState('Unknown');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const runDiagnostics = async () => {
      try {
        setStatus('Testing basic page load...');
        
        // Test API connectivity
        setStatus('Testing API connectivity...');
        const apiResponse = await fetch('/api/debug');
        setApiStatus(apiResponse.ok ? 'Working' : `Failed (${apiResponse.status})`);
        
        // Test database connectivity
        setStatus('Testing database connectivity...');
        const dbResponse = await fetch('/api/creatives');
        setDbStatus(dbResponse.ok ? 'Working' : `Failed (${dbResponse.status})`);
        
        setStatus('Diagnostics complete');
      } catch (err) {
        setError(`Error: ${(err as Error).message}`);
        setStatus('Failed');
      }
    };

    runDiagnostics();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow p-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">System Diagnostics</h1>
        
        {error ? (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            <strong>Error:</strong> {error}
          </div>
        ) : null}
        
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded">
            <span className="font-medium">Page Status:</span>
            <span className={`px-3 py-1 rounded-full text-sm ${
              status === 'Diagnostics complete' ? 'bg-green-100 text-green-800' : 
              status === 'Failed' ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
            }`}>
              {status}
            </span>
          </div>
          
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded">
            <span className="font-medium">API Status:</span>
            <span className={`px-3 py-1 rounded-full text-sm ${
              apiStatus === 'Working' ? 'bg-green-100 text-green-800' : 
              apiStatus.startsWith('Failed') ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
            }`}>
              {apiStatus}
            </span>
          </div>
          
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded">
            <span className="font-medium">Database Status:</span>
            <span className={`px-3 py-1 rounded-full text-sm ${
              dbStatus === 'Working' ? 'bg-green-100 text-green-800' : 
              dbStatus.startsWith('Failed') ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
            }`}>
              {dbStatus}
            </span>
          </div>
          
          <div className="mt-8 p-4 bg-blue-50 rounded">
            <h2 className="font-bold text-lg mb-2">Next Steps:</h2>
            <ul className="list-disc pl-5 space-y-1 text-gray-700">
              <li>If all statuses are green, the basic system is working</li>
              <li>If any status is red, there's a specific issue to address</li>
              <li>Check browser console for detailed error messages</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}