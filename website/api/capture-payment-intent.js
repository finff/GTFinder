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
    const { paymentIntentId } = req.body || {};

    if (!paymentIntentId) {
      return res.status(400).json({ error: 'Payment Intent ID is required' });
    }

    const paymentIntent = await getStripe().paymentIntents.capture(paymentIntentId);
    return res.json({ success: true, paymentIntent });
  } catch (error) {
    return sendError(res, error);
  }
};
