import { describe, expect, it } from "vitest";

import manifest from "./manifest";

describe("PWA manifest", () => {
  it("popisuje instalovatelnou aplikaci a její shell", () => {
    expect(manifest()).toMatchObject({
      id: "/",
      name: "Aktivní nákup",
      start_url: "/",
      scope: "/",
      display: "standalone",
      background_color: "#f8f5ec",
      theme_color: "#174f3a",
    });
  });

  it("nabízí běžnou i maskovatelnou ikonu", () => {
    const icons = manifest().icons ?? [];

    expect(icons).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ sizes: "192x192", purpose: "any" }),
        expect.objectContaining({ sizes: "512x512", purpose: "maskable" }),
      ]),
    );
  });
});
