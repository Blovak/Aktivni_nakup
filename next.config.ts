import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        source: "/sw.js",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=0, must-revalidate",
          },
          {
            key: "Service-Worker-Allowed",
            value: "/",
          },
        ],
      },
    ];
  },
  cacheComponents: true,
  experimental: {
    // Next.js 16 CLI type checking currently loses captured tsc output under
    // Node.js 24. TypeScript 5 still exposes the supported compiler API.
    useTypeScriptCli: false,
  },
  partialPrefetching: true,
};

export default nextConfig;
