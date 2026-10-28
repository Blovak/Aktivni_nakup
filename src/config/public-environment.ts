import { parsePublicEnvironment } from "./environment-schema";

export function getPublicEnvironment() {
  return parsePublicEnvironment({
    // Static property access is required so Next.js can inline public values.
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  });
}
