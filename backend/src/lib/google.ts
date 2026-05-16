import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env.js';

const client = new OAuth2Client(env.GOOGLE_CLIENT_ID || undefined);

export async function verifyGoogleIdToken(idToken: string) {
  if (!env.GOOGLE_CLIENT_ID) {
    throw new Error('GOOGLE_CLIENT_ID is not configured');
  }

  const ticket = await client.verifyIdToken({
    idToken,
    audience: env.GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();
  if (!payload?.email) {
    throw new Error('Google payload missing email');
  }

  return {
    email: payload.email,
    firstName: payload.given_name ?? '',
    lastName: payload.family_name ?? '',
    profilePhoto: payload.picture ?? '',
    providerUserId: payload.sub,
  };
}
