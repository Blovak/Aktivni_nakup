import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  title: "Aktivní nákup",
  description: "Společný nákupní seznam seřazený pro vaši prodejnu.",
};

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#174f3a",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="cs">
      <body>{children}</body>
    </html>
  );
}
