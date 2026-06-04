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
    const { paymentIntentId, reason } = req.body || {};

    if (!paymentIntentId) {
      return res.status(400).json({ error: 'Payment Intent ID is required' });
    }

    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === 'succeeded') {
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
        reason: reason || 'requested_by_customer',
      });

      return res.json({
        success: true,
        refundId: refund.id,
        status: refund.status,
      });
    }

    if (paymentIntent.status === 'requires_capture') {
      const cancelledIntent = await stripe.paymentIntents.cancel(paymentIntentId);
      return res.json({
        success: true,
        status: cancelledIntent.status,
      });
    }

    return res.status(400).json({
      success: false,
      status: paymentIntent.status,
      message: `Payment cannot be refunded or canceled in its current state: ${paymentIntent.status}`,
    });
  } catch (error) {
    return sendError(res, error);
  }
};
