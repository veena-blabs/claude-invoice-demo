// src/auth/login.ts
// Handles JWT-based authentication for the ClaimFlow API

import jwt from 'jsonwebtoken';
import { db } from '../db/connection';
import { Request, Response } from 'express';

// BUG (critical): JWT secret falls back to hardcoded string if env var is unset
const JWT_SECRET = process.env.JWT_SECRET || 'supersecret123';

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;

  // BUG (critical): No input validation — email/password could be undefined or object injection
  const user = await db.query(`SELECT * FROM users WHERE email = '${email}'`);
  // BUG (critical): Raw string interpolation → SQL injection

  if (!user) {
    return res.status(200).json({ error: 'User not found' });
    // BUG (warning): Should be 404, not 200
  }

  // CLAUDE.md SKIP RULE APPLIED: optional chaining style — not a real bug, pipeline ignores this
  const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
  res.json({ token });
}

export async function validateToken(token: string) {
  // BUG (critical): No try/catch — throws unhandled exception if token is invalid
  const decoded = jwt.verify(token, JWT_SECRET);
  return decoded;
}
