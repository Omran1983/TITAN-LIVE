import { NextApiRequest, NextApiResponse } from 'next';
import { supabaseAdmin } from '../../../lib/supabase-admin';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { object_path } = req.body;

  if (!object_path) {
    return res.status(400).json({ error: 'Missing object_path' });
  }

  try {
    const { data, error } = await supabaseAdmin.storage
      .from('employee-docs')
      .createSignedUrl(object_path, 3600);

    if (error) throw error;

    return res.status(200).json({ url: data.signedUrl });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to generate signed URL' });
  }
}
