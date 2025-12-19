import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class StripeCheckoutScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final double price;
  final String userId;
  final String userEmail;

  const StripeCheckoutScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.price,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  bool _isLoading = true;
  String? _errorMessage;



  String backendUrl = 'https://apps.codefied.co/woodland';

  @override
  void initState() {
    super.initState();
    _createCheckoutSession();
  }

  Future<void> _createCheckoutSession() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Deep link URLs for success and cancel
      // These will redirect back to the app after payment
      // Include session_id placeholder which Stripe will replace
      final successUrl =
          'stripe://payment-success?bookId=${widget.bookId}&userId=${widget.userId}&session_id={CHECKOUT_SESSION_ID}';
      final cancelUrl = 'stripe://payment-cancel';

      final response = await http
          .post(
            Uri.parse('$backendUrl/create-checkout-session'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'bookId': widget.bookId,
              'bookTitle': widget.bookTitle,
              'price': widget.price,
              'userId': widget.userId,
              'userEmail': widget.userEmail,
              'successUrl': successUrl,
              'cancelUrl': cancelUrl,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkoutUrl = data['url'] as String?;

        if (checkoutUrl != null) {
          setState(() {
            _isLoading = false;
          });

          // Open Stripe checkout in external browser
          await _openStripeCheckout(checkoutUrl);
        } else {
          setState(() {
            _errorMessage = 'No checkout URL received from server';
            _isLoading = false;
          });
        }
      } else {
        final errorBody = response.body.isNotEmpty
            ? json.decode(response.body)
            : {'error': 'Unknown error'};

        setState(() {
          _errorMessage =
              'Failed to create checkout session.\n\n'
              'Status: ${response.statusCode}\n'
              'Error: ${errorBody['error'] ?? response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      print('📍 Backend URL: $backendUrl');

      String errorMsg = 'Error connecting to backend server.\n\n';

      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        errorMsg += '⚠️ Cannot connect to backend server.\n\n';
        errorMsg += 'Please check:\n';
        errorMsg += '1. Backend server is running\n';
        errorMsg += '2. Correct URL: $backendUrl\n';
        errorMsg += '3. Check your internet connection\n';
      } else if (e.toString().contains('timeout')) {
        errorMsg += '⚠️ Request timeout - Backend server not responding.\n\n';
        errorMsg += 'Please check if backend is running on: $backendUrl';
      } else {
        errorMsg += 'Error: ${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _openStripeCheckout(String url) async {
    try {
      final uri = Uri.parse(url);

      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        // Launch in external browser (Chrome, Safari, etc.)
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external browser
        );

        if (launched) {
          print('✅ Stripe checkout opened in external browser');
          // Don't close the screen yet - wait for deep link callback
          // The screen will be closed when deep link is received
        } else {
          setState(() {
            _errorMessage = 'Failed to open Stripe checkout page';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Cannot open Stripe checkout URL';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error opening Stripe checkout: $e');
      setState(() {
        _errorMessage = 'Error opening checkout: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'success': false, 'error': 'Payment cancelled by user'});
          },
        ),
        title: Text(
          'Stripe Checkout',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            16.verticalSpace,
            Text(
              'Opening Stripe Checkout...',
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
              16.verticalSpace,
              Text(
                'Error',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
              8.verticalSpace,
              Text(
                _errorMessage!,
                style: AppTextStyles.regular.copyWith(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              24.verticalSpace,
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop({'success': false, 'error': _errorMessage});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  'Close',
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.black,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show message that checkout is opening
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, color: AppColors.primaryColor, size: 64.sp),
            16.verticalSpace,
            Text(
              'Opening Stripe Checkout',
              style: AppTextStyles.lufgaMedium.copyWith(
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            8.verticalSpace,
            Text(
              'The payment page will open in your browser.\n'
              'After completing the payment, you will be redirected back to the app.',
              style: AppTextStyles.regular.copyWith(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
