import { redirect } from 'next/navigation';

export default function Home() {
  // Redirect to dashboard without authentication
  redirect('/dashboard');
}