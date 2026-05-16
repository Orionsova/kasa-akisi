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
    return res.status(400).json({
      message: 'Validation error',
      errors: error.flatten().fieldErrors,
    });
  }

  if (error instanceof Error) {
    return res.status(500).json({ message: error.message });
  }

  return res.status(500).json({ message: 'Internal server error' });
}
