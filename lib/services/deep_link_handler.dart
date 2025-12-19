import 'package:flutter/material.dart';
import '../main.dart';

class DeepLinkHandler {
  static void handleStripeDeepLink(String url) {
    print('🔗 Deep link received: $url');
    
    final uri = Uri.parse(url);
    
    if (uri.scheme == 'stripe') {
      if (uri.host == 'payment-success') {
        // Extract parameters from deep link
        final bookId = uri.queryParameters['bookId'];
        final userId = uri.queryParameters['userId'];
        final sessionId = uri.queryParameters['session_id'];
        
        print('✅ Payment success - bookId: $bookId, userId: $userId, sessionId: $sessionId');
        
        // Pop the checkout screen with success result
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pop({
            'success': true,
            'paymentId': sessionId,
            'transactionId': sessionId,
            'amount': null, // Will be fetched from Stripe if needed
            'timestamp': DateTime.now().toIso8601String(),
            'bookId': bookId,
            'userId': userId,
          });
        }
      } else if (uri.host == 'payment-cancel') {
        print('❌ Payment cancelled');
        
        // Pop the checkout screen with cancel result
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pop({
            'success': false,
            'error': 'Payment cancelled by user',
          });
        }
      }
    }
  }
}

