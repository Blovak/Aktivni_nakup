import {
  parsePublicEnvironment,
  parseServerEnvironment,
} from "../src/config/environment-schema.ts";

parsePublicEnvironment({
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
});

parseServerEnvironment({
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  DATABASE_URL: process.env.DATABASE_URL,
});

console.log("Konfigurace prostředí je platná.");
