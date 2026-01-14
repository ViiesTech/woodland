import 'dart:async';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';

class StripeService {
  // Stripe live publishable key
  static const String stripeTestPublishableKey =
      'pk_live_51SG0n8DpfvqzBzFilSGwrGzKH18BSrZRlJu97UZ98m1O1q7fSsUJpNDNXVamqTAKEkEYJH4pjY4Jr80jBiq6STq200ZkXuVe03';

  // Use 10.0.2.2 for Android emulator to access localhost
  static const String backendUrl = 'http://10.0.2.2:3004';

  /// Start Stripe payment flow
  /// 1. Create Checkout Session
  /// 2. Launch external browser
  /// 3. Listen for deep link callback
  static Future<Map<String, dynamic>?> startPayment({
    required String bookId,
    required String bookTitle,
    required double price,
    required String userId,
    required String userEmail,
  }) async {
    final appLinks = AppLinks();
    StreamSubscription<Uri>? linkSubscription;
    final completer = Completer<Map<String, dynamic>?>();

    try {
      // 1. Setup Deep Link Listener
      linkSubscription = appLinks.uriLinkStream.listen(
        (uri) {
          if (uri.scheme == 'stripe') {
            if (uri.host == 'payment-success') {
              if (!completer.isCompleted) {
                // Extract session_id or other params if needed
                // final sessionId = uri.queryParameters['session_id'];
                completer.complete({'success': true});
              }
            } else if (uri.host == 'payment-cancel') {
              if (!completer.isCompleted) {
                completer.complete({
                  'success': false,
                  'error': 'Payment cancelled',
                });
              }
            }
          }
        },
        onError: (err) {
          print('❌ Deep link error: $err');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      // 2. Create Checkout Session
      final successUrl =
          'stripe://payment-success?bookId=$bookId&userId=$userId&session_id={CHECKOUT_SESSION_ID}';
      final cancelUrl = 'stripe://payment-cancel';

      final response = await http
          .post(
            Uri.parse('$backendUrl/create-checkout-session'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'bookId': bookId,
              'bookTitle': bookTitle,
              'price': price,
              'userId': userId,
              'userEmail': userEmail,
              'successUrl': successUrl,
              'cancelUrl': cancelUrl,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to create session: ${response.body}');
      }

      final data = json.decode(response.body);
      final checkoutUrl = data['url'] as String?;

      if (checkoutUrl == null) {
        throw Exception('No checkout URL returned');
      }

      // 3. Launch External Browser
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch payment URL');
      }

      // 4. Wait for Deep Link or Timeout (e.g., 5 minutes)
      // We return the future so the caller waits until the deep link triggers the completer
      // OR the user manually goes back to the app (which we can't easily detect as "cancel" unless they hit the specific link)
      // For a better UX, we might want to let the user "Cancel" from the UI if they get stuck.
      // However, for this implementation, we wait for the link.

      return await completer.future;
    } catch (e) {
      print('Payment Error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      linkSubscription?.cancel();
    }
  }
}
