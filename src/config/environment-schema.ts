import { z } from "zod";

const publicEnvironmentSchema = z.strictObject({
  NEXT_PUBLIC_SUPABASE_URL: z.url({
    error: "Musí být platná absolutní URL.",
  }),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z
    .string({ error: "Proměnná je povinná." })
    .min(16, "Hodnota je příliš krátká."),
});

const serverEnvironmentSchema = z.strictObject({
  SUPABASE_SERVICE_ROLE_KEY: z
    .string({ error: "Proměnná je povinná." })
    .min(16, "Hodnota je příliš krátká."),
  DATABASE_URL: z
    .string({ error: "Proměnná je povinná." })
    .regex(/^postgres(?:ql)?:\/\//u, "Musí být PostgreSQL connection string."),
});

export type PublicEnvironment = z.infer<typeof publicEnvironmentSchema>;
export type ServerEnvironment = z.infer<typeof serverEnvironmentSchema>;

export class EnvironmentConfigurationError extends Error {
  readonly issues: readonly string[];

  constructor(scope: "veřejná" | "serverová", issues: readonly string[]) {
    super(`Neplatná ${scope} konfigurace prostředí:\n- ${issues.join("\n- ")}`);
    this.name = "EnvironmentConfigurationError";
    this.issues = issues;
  }
}

function formatIssues(error: z.ZodError): string[] {
  return error.issues.map((issue) => {
    if (issue.code === "unrecognized_keys") {
      return `Neočekávané proměnné: ${issue.keys.join(", ")}.`;
    }

    const path = issue.path.join(".") || "prostředí";
    return `${path}: ${issue.message}`;
  });
}

export function parsePublicEnvironment(input: unknown): PublicEnvironment {
  const result = publicEnvironmentSchema.safeParse(input);

  if (!result.success) {
    throw new EnvironmentConfigurationError(
      "veřejná",
      formatIssues(result.error),
    );
  }

  return result.data;
}

export function parseServerEnvironment(input: unknown): ServerEnvironment {
  const result = serverEnvironmentSchema.safeParse(input);

  if (!result.success) {
    throw new EnvironmentConfigurationError(
      "serverová",
      formatIssues(result.error),
    );
  }

  return result.data;
}
