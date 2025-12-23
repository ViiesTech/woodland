import 'package:flutter/material.dart';
import '../screens/payment/stripe_checkout_screen.dart';

class StripeService {
  // Stripe live publishable key
  static const String stripeTestPublishableKey =
      'pk_live_51SG0n8DpfvqzBzFilSGwrGzKH18BSrZRlJu97UZ98m1O1q7fSsUJpNDNXVamqTAKEkEYJH4pjY4Jr80jBiq6STq200ZkXuVe03';

  /// Open Stripe Checkout for book purchase using InAppWebView
  /// Returns payment result with details or null if cancelled
  static Future<Map<String, dynamic>?> openStripeCheckout({
    required BuildContext context,
    required String bookId,
    required String bookTitle,
    required double price,
    required String userId,
    required String userEmail,
  }) async {
    try {
      // Navigate to Stripe checkout screen
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => StripeCheckoutScreen(
            bookId: bookId,
            bookTitle: bookTitle,
            price: price,
            userId: userId,
            userEmail: userEmail,
          ),
        ),
      );

      return result;
    } catch (e) {
      print('Error opening Stripe checkout: $e');
      return null;
    }
  }
}

