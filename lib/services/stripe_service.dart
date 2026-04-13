import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart'; // Required for WidgetsBindingObserver
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';

class StripeService {
  // ... existing constants ...
  // Stripe live publishable key
  static const String stripeTestPublishableKey =
      'pk_live_51SG0n8DpfvqzBzFilSGwrGzKH18BSrZRlJu97UZ98m1O1q7fSsUJpNDNXVamqTAKEkEYJH4pjY4Jr80jBiq6STq200ZkXuVe03';
  // 'pk_test_51QkTfNEtXkWvOEBqD21BzP7lB1MbpJvo7ijAlGBctZo6qNlLCzfqUtGy9wgGS2jf04swfAYja3VGQm3IcZzm504400S1R4yg1f';

  // Production backend URL
  static const String backendUrl = 'https://apps.codefied.co/woodland/prod';
  
  // Local development URL (for testing on physical device)
  // To find your local IP on macOS: run `ipconfig getifaddr en0` in terminal
  // Make sure your phone and computer are on the same WiFi network
  // static const String backendUrl = 'http://192.168.100.67:3004';

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
    _PaymentLifecycleObserver? observer;

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

      // 4. Wait for Deep Link or Timeout
      // We also listen for App Lifecycle changes to detect manual return
      observer = _PaymentLifecycleObserver(completer);
      WidgetsBinding.instance.addObserver(observer);

      return await completer.future;
    } on TimeoutException catch (_) {
      print('❌ Timeout connecting to backend');
      return {
        'success': false,
        'error':
            'Connection timed out. Ensure server is running at $backendUrl',
      };
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Cannot reach server. Check IP/Port.',
      };
    } catch (e) {
      print('❌ Payment Error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      linkSubscription?.cancel();
      if (observer != null) {
        WidgetsBinding.instance.removeObserver(observer);
      }
    }
  }
}

/// Helper class to detect when user manually returns to the app
class _PaymentLifecycleObserver extends WidgetsBindingObserver {
  final Completer<Map<String, dynamic>?> completer;

  _PaymentLifecycleObserver(this.completer);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to app.
      // If payment was successful, the Deep Link should have fired (or will fire very soon).
      // We give it a short buffer. If not completed by then, assume cancel.
      Future.delayed(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.complete({'success': false, 'error': 'Payment cancelled'});
        }
      });
    }
  }
}
