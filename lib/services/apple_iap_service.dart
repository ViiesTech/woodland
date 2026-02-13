import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class AppleIAPService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Callback for when purchase completes
  static Function(PurchaseDetails)? onPurchaseComplete;
  static Function(String)? onPurchaseError;

  /// Initialize IAP connection and listen for purchases
  static Future<bool> initialize() async {
    if (!Platform.isIOS) {
      print('⚠️ Apple IAP only works on iOS');
      return false;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      print('❌ IAP not available on this device');
      return false;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        print('❌ Purchase stream error: $error');
        onPurchaseError?.call(error.toString());
      },
    );

    print('✅ Apple IAP initialized');
    return true;
  }

  /// Handle purchase updates from the stream
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      print('📦 Purchase update: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('⏳ Purchase pending...');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          print('✅ Purchase successful!');
          onPurchaseComplete?.call(purchaseDetails);
          break;

        case PurchaseStatus.error:
          print('❌ Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Purchase failed',
          );
          break;

        case PurchaseStatus.canceled:
          print('🚫 Purchase canceled by user');
          onPurchaseError?.call('Purchase canceled');
          break;
      }

      // Complete the purchase (required by Apple)
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Get product details from App Store
  /// productIds should be like: ['book_abc123', 'book_def456']
  static Future<List<ProductDetails>> getProducts(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) {
      print('⚠️ No product IDs provided');
      return [];
    }

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        productIds.toSet(),
      );

      if (response.error != null) {
        print('❌ Error fetching products: ${response.error}');
        return [];
      }

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found: ${response.notFoundIDs}');
      }

      print('✅ Found ${response.productDetails.length} products');
      return response.productDetails;
    } catch (e) {
      print('❌ Exception fetching products: $e');
      return [];
    }
  }

  /// Get a single product by ID
  static Future<ProductDetails?> getProduct(String productId) async {
    final products = await getProducts([productId]);
    return products.isEmpty ? null : products.first;
  }

  /// Purchase a book
  /// productId should be like: 'book_abc123'
  static Future<bool> purchaseBook(String productId) async {
    try {
      // Get product details first
      final product = await getProduct(productId);

      if (product == null) {
        print('❌ Product not found: $productId');
        onPurchaseError?.call('Product not found in App Store');
        return false;
      }

      print('🛒 Starting purchase for: ${product.title}');

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Start the purchase flow
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        print('❌ Failed to initiate purchase');
        onPurchaseError?.call('Failed to start purchase');
      }

      return success;
    } catch (e) {
      print('❌ Purchase exception: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  /// Restore previous purchases
  static Future<void> restorePurchases() async {
    try {
      print('🔄 Restoring purchases...');
      await _iap.restorePurchases();
      print('✅ Restore complete');
    } catch (e) {
      print('❌ Restore error: $e');
      onPurchaseError?.call('Failed to restore purchases');
    }
  }

  /// Get receipt data for backend verification
  static Future<String?> getReceiptData(PurchaseDetails purchase) async {
    if (Platform.isIOS) {
      // For iOS, get the receipt from StoreKit
      final iosPurchase = purchase as AppStorePurchaseDetails;

      // Get the app receipt (contains all purchases)
      try {
        final receipt = await SKReceiptManager.retrieveReceiptData();
        return receipt;
      } catch (e) {
        print('❌ Error getting receipt: $e');
        return null;
      }
    }
    return null;
  }

  /// Clean up
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    onPurchaseComplete = null;
    onPurchaseError = null;
  }

  /// Convert book price to product ID (Price Tier Strategy)
  /// Example: 3.99 -> 'book_tier_399'
  static String priceToProductId(double price) {
    if (price == 0) return 'book_free';

    // We use book_tier_399 for your $3.99 books
    final cents = (price * 100).round();
    return 'book_tier_$cents';
  }

  /// Get available price tiers
  static List<String> getAvailablePriceTiers() {
    return [
      'book_tier_399', // Your new standard price ($3.99)
      'book_tier_99',
      'book_tier_499',
    ];
  }

  /// Purchase a book using price tier
  static Future<bool> purchaseBookByPrice(double price) async {
    try {
      final productId = priceToProductId(price);

      // Get product details
      final product = await getProduct(productId);

      if (product == null) {
        print('❌ Product not found: $productId');
        onPurchaseError?.call('Price tier not available: \$$price');
        return false;
      }

      print('🛒 Starting purchase for price tier: $productId (\$$price)');

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Use buyConsumable for price tiers (allows multiple purchases)
      final bool success = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        print('❌ Failed to initiate purchase');
        onPurchaseError?.call('Failed to start purchase');
      }

      return success;
    } catch (e) {
      print('❌ Purchase exception: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }
}
