import "server-only";

import { parseServerEnvironment } from "./environment-schema";

export function getServerEnvironment() {
  return parseServerEnvironment({
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
    DATABASE_URL: process.env.DATABASE_URL,
  });
}
