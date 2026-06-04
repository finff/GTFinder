const {
  getStripe,
  handleOptions,
  requireMethod,
  sendError,
  setCors,
} = require('./_stripe');

module.exports = async function handler(req, res) {
  setCors(res);
  if (handleOptions(req, res) || !requireMethod(req, res, 'GET')) {
    return;
  }

  try {
    const { paymentIntentId } = req.query || {};

    if (!paymentIntentId) {
      return res.status(400).json({ error: 'Payment Intent ID is required' });
    }

    const paymentIntent = await getStripe().paymentIntents.retrieve(paymentIntentId);
    return res.json({
      status: paymentIntent.status,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      created: paymentIntent.created,
    });
  } catch (error) {
    return sendError(res, error);
  }
};
