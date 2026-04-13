const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

// Get Stripe secret key from environment variables
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;

if (!STRIPE_SECRET_KEY) {
  console.error('Please set STRIPE_SECRET_KEY in your .env file or environment variables.');
  console.error('See .env.example for reference.');
  process.exit(1);
}

const stripe = require('stripe')(STRIPE_SECRET_KEY);

const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(cors(
  {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }
));
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Stripe backend is running' });
});

// Create Stripe Checkout Session
app.post('/create-checkout-session', async (req, res) => {
  try {
    const { bookId, bookTitle, price, userId, userEmail, successUrl, cancelUrl } = req.body;

    // Validate required fields
    if (!bookId || !bookTitle || !price || !userId || !userEmail) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: bookTitle,
            },
            unit_amount: Math.round(price * 100), // Convert to cents
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: successUrl || 'stripe://payment-success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: cancelUrl || 'stripe://payment-cancel',
      customer_email: userEmail,
      metadata: {
        bookId: bookId,
        userId: userId,
        bookTitle: bookTitle,
      },
    });

    // Return checkout URL
    res.json({
      url: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Stripe backend server running on port ${PORT}`);
  console.log(`📍 Local URL: http://localhost:${PORT}`);
  console.log(`💳 Using Stripe key: ${STRIPE_SECRET_KEY.substring(0, 12)}...`);
  console.log(`\n✅ Ready to accept payment requests!`);
});

