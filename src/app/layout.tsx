import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import { ServiceWorkerManager } from "@/components/pwa/service-worker-manager";

import "./globals.css";

export const metadata: Metadata = {
  applicationName: "Aktivní nákup",
  title: "Aktivní nákup",
  description: "Společný nákupní seznam seřazený pro vaši prodejnu.",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Aktivní nákup",
  },
};

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#174f3a",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="cs">
      <body>
        {children}
        <ServiceWorkerManager />
      </body>
    </html>
  );
}
