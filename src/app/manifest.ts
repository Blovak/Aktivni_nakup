import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    name: "Aktivní nákup",
    short_name: "Nákup",
    description: "Společný rodinný nákupní seznam.",
    start_url: "/",
    scope: "/",
    display: "standalone",
    background_color: "#f8f5ec",
    theme_color: "#174f3a",
    lang: "cs",
    categories: ["shopping", "lifestyle"],
    icons: [
      {
        src: "/icons/icon-192.svg",
        sizes: "192x192",
        type: "image/svg+xml",
        purpose: "any",
      },
      {
        src: "/icons/icon-512.svg",
        sizes: "512x512",
        type: "image/svg+xml",
        purpose: "any",
      },
      {
        src: "/icons/icon-512.svg",
        sizes: "512x512",
        type: "image/svg+xml",
        purpose: "maskable",
      },
    ],
  };
}
