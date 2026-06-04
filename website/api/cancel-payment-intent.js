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

    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === 'requires_capture') {
      await stripe.paymentIntents.cancel(paymentIntentId);
      return res.json({ success: true, cancelled: true });
    }

    if (paymentIntent.status === 'succeeded') {
      await stripe.refunds.create({ payment_intent: paymentIntentId });
      return res.json({ success: true, refunded: true });
    }

    return res.json({ success: false, message: 'Nothing to cancel or refund.' });
  } catch (error) {
    return sendError(res, error);
  }
};
