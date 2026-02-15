import type { VercelResponse } from "@vercel/node";

export function sendError(
  res: VercelResponse,
  status: number,
  error: string
): void {
  res.status(status).json({ error });
}

export function getQueryValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return value[0] ?? "";
  }
  return value ?? "";
}

export function toTrimmedString(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.trim();
}
