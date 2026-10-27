export type NormalizedShoppingItemLabel = Readonly<{
  label: string;
  normalizedLabel: string;
}>;

export function normalizeShoppingItemLabel(
  input: string,
): NormalizedShoppingItemLabel {
  const label = input.trim();

  if (label.length === 0) {
    throw new Error("Název položky nesmí být prázdný.");
  }

  return {
    label,
    normalizedLabel: label
      .normalize("NFKC")
      .toLocaleLowerCase("cs-CZ")
      .replace(/\s+/gu, " "),
  };
}
