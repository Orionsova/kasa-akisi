import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';

export function notFoundHandler(_req: Request, res: Response) {
  return res.status(404).json({ message: 'Not found' });
}

export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  if (error instanceof ZodError) {
    const flattened = error.flatten().fieldErrors;
    const firstFieldError = Object.values(flattened)
      .flat()
      .find((message): message is string => Boolean(message && message.length));
    return res.status(400).json({
      message: firstFieldError ?? 'Validation error',
      errors: flattened,
    });
  }

  if (error instanceof Error) {
    return res.status(500).json({ message: error.message });
  }

  return res.status(500).json({ message: 'Internal server error' });
}
