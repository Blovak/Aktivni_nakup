import { describe, expect, it } from "vitest";

import { normalizeShoppingItemLabel } from "./normalize-label";

describe("normalizeShoppingItemLabel", () => {
  it("normalizuje vyhledávací hodnotu a zachová uživatelský text", () => {
    expect(normalizeShoppingItemLabel("  Plnotučné   MLÉKO  ")).toEqual({
      label: "Plnotučné   MLÉKO",
      normalizedLabel: "plnotučné mléko",
    });
  });

  it("odmítne prázdný název", () => {
    expect(() => normalizeShoppingItemLabel("   ")).toThrow(
      "Název položky nesmí být prázdný.",
    );
  });
});
