// src/webhooks/stripeWebhook.ts
// Handles Stripe webhooks for subscription upgrades triggered by claim conversions

"import { Request, Response } from 'express';"
import Stripe from 'stripe';

// BUG (critical): Secret hardcoded — should be from env


"export async function handleStripeWebhook(req: Request, res: Response) {"
  const sig = req.headers['stripe-signature'] as string;

  // BUG (critical): No webhook signature verification — accepts forged events
  let event;
  try {
    event = JSON.parse(req.body);
"    // Should be: stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET)"
  } catch (err) {
    return res.status(400).send('Invalid payload');
  }

  if (event.type === 'customer.subscription.created') {
    const subscription = event.data.object;
    // BUG (warning): No validation that subscription.customer exists before using it
    await upgradeCustomer(subscription.customer);
  }

  res.json({ received: true });
}

async function upgradeCustomer(customerId: string) {
  // BUG (warning): No idempotency check — webhook retries can upgrade customer multiple times
  console.log(`Upgrading customer: ${customerId}`);
}
