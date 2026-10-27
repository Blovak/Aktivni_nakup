import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
  experimental: {
    // Next.js 16 CLI type checking currently loses captured tsc output under
    // Node.js 24. TypeScript 5 still exposes the supported compiler API.
    useTypeScriptCli: false,
  },
  partialPrefetching: true,
};

export default nextConfig;
