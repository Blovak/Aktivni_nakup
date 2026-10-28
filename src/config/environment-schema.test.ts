import { describe, expect, it } from "vitest";

import {
  EnvironmentConfigurationError,
  parsePublicEnvironment,
  parseServerEnvironment,
} from "./environment-schema";

const validPublicEnvironment = {
  NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
};

const validServerEnvironment = {
  SUPABASE_SERVICE_ROLE_KEY: "sb_secret_example",
  DATABASE_URL: "postgresql://postgres:example@127.0.0.1:54322/postgres",
};

describe("parsePublicEnvironment", () => {
  it("vrátí pouze validovanou veřejnou konfiguraci", () => {
    expect(parsePublicEnvironment(validPublicEnvironment)).toEqual(
      validPublicEnvironment,
    );
  });

  it("pojmenuje chybějící proměnnou bez vypsání jejích hodnot", () => {
    expect(() =>
      parsePublicEnvironment({
        NEXT_PUBLIC_SUPABASE_URL: "not-a-url",
      }),
    ).toThrowError(/NEXT_PUBLIC_SUPABASE_(URL|PUBLISHABLE_KEY)/u);

    try {
      parsePublicEnvironment({ NEXT_PUBLIC_SUPABASE_URL: "not-a-url" });
    } catch (error) {
      expect(error).toBeInstanceOf(EnvironmentConfigurationError);
      expect(String(error)).not.toContain("sb_secret");
    }
  });

  it("odmítne chybně pojmenovanou veřejnou proměnnou", () => {
    expect(() =>
      parsePublicEnvironment({
        ...validPublicEnvironment,
        NEXT_PUBLIC_SUPABASE_PUBLIC_KEY: "sb_publishable_typo",
      }),
    ).toThrowError(/NEXT_PUBLIC_SUPABASE_PUBLIC_KEY/u);
  });
});

describe("parseServerEnvironment", () => {
  it("vrátí validovanou serverovou konfiguraci", () => {
    expect(parseServerEnvironment(validServerEnvironment)).toEqual(
      validServerEnvironment,
    );
  });

  it("odmítne chybějící serverové tajemství", () => {
    expect(() =>
      parseServerEnvironment({
        DATABASE_URL: validServerEnvironment.DATABASE_URL,
      }),
    ).toThrowError(/SUPABASE_SERVICE_ROLE_KEY/u);
  });

  it("nikdy nevypíše neplatnou citlivou hodnotu do chyby", () => {
    expect.assertions(2);
    const sensitiveValue = "invalid://private-user:private-password";

    try {
      parseServerEnvironment({
        ...validServerEnvironment,
        DATABASE_URL: sensitiveValue,
      });
    } catch (error) {
      expect(error).toBeInstanceOf(EnvironmentConfigurationError);
      expect(String(error)).not.toContain(sensitiveValue);
    }
  });
});
