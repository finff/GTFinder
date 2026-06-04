const {
  getStripe,
  handleOptions,
  requireMethod,
  sendError,
  setCors,
} = require('./_stripe');

module.exports = async function handler(req, res) {
  setCors(res);
  if (handleOptions(req, res) || !requireMethod(req, res, 'POST')) {
    return;
  }

  try {
    const { amount, currency = 'myr' } = req.body || {};

    if (!amount || Number.isNaN(Number(amount))) {
      return res.status(400).json({ error: 'A valid amount is required' });
    }

    const paymentIntent = await getStripe().paymentIntents.create({
      amount: Number.parseInt(amount, 10),
      currency: String(currency).toLowerCase(),
      capture_method: 'manual',
      automatic_payment_methods: {
        enabled: true,
      },
    });

    return res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      id: paymentIntent.id,
    });
  } catch (error) {
    return sendError(res, error);
  }
};
