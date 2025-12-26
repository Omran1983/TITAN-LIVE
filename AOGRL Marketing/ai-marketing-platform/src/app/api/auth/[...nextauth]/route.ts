// Disable NextAuth by returning a 404 response
// For static export compatibility
export const dynamic = "force-static";

export function GET() {
  return new Response('NextAuth disabled', { status: 404 });
}

export function POST() {
  return new Response('NextAuth disabled', { status: 404 });
}