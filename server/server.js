require('dotenv').config();
const express = require('express');
const cors = require('cors');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'myr',
      capture_method: 'manual',
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (e) {
    console.error('Error creating payment intent:', e);
    res.status(500).json({ error: e.message });
  }
});

app.post('/capture-payment-intent', async (req, res) => {
  try {
    const { paymentIntentId } = req.body;
    const paymentIntent = await stripe.paymentIntents.capture(paymentIntentId);
    res.json({ success: true, paymentIntent });
  } catch (e) {
    console.error('Error capturing payment intent:', e);
    res.status(500).json({ error: e.message });
  }
});

app.post('/cancel-payment-intent', async (req, res) => {
  try {
    const { paymentIntentId } = req.body;
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    if (paymentIntent.status === 'requires_capture') {
      // Not captured yet, just cancel
      await stripe.paymentIntents.cancel(paymentIntentId);
      res.json({ success: true, cancelled: true });
    } else if (paymentIntent.status === 'succeeded') {
      // Already captured, refund
      await stripe.refunds.create({ payment_intent: paymentIntentId });
      res.json({ success: true, refunded: true });
    } else {
      res.json({ success: false, message: 'Nothing to cancel or refund.' });
    }
  } catch (e) {
    console.error('Error cancelling/refunding payment intent:', e);
    res.status(500).json({ error: e.message });
  }
});

app.listen(8080, '0.0.0.0', () => {
  console.log(`Server running on port 8080`);
}); 