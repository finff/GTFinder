const stripe = require('stripe');

let stripeClient;

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function handleOptions(req, res) {
  if (req.method !== 'OPTIONS') {
    return false;
  }

  setCors(res);
  res.status(204).end();
  return true;
}

function requireMethod(req, res, method) {
  if (req.method === method) {
    return true;
  }

  res.status(405).json({ error: `Method ${req.method} not allowed` });
  return false;
}

function getStripe() {
  if (!process.env.STRIPE_SECRET_KEY) {
    throw new Error('STRIPE_SECRET_KEY is not configured');
  }

  if (!stripeClient) {
    stripeClient = stripe(process.env.STRIPE_SECRET_KEY);
  }

  return stripeClient;
}

function sendError(res, error) {
  const message = error instanceof Error ? error.message : 'Unexpected server error';
  res.status(500).json({ error: message });
}

module.exports = {
  getStripe,
  handleOptions,
  requireMethod,
  sendError,
  setCors,
};
