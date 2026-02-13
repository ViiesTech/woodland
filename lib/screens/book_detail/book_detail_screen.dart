import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/size_constants.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';

import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../reading/reading_screen.dart';
import '../reading/listen_screen.dart';
import '../../admin_panel/screens/edit_book_screen.dart';
import '../../components/switch/custom_switch.dart';
import '../../services/book_service.dart';
import '../../components/utils/custom_toast.dart';
import '../../services/bookmark_service.dart';
import '../../services/viewed_books_service.dart';
import '../../services/purchase_service.dart';
import '../../services/stripe_service.dart';
import '../../services/apple_iap_service.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late BookModel _book;
  bool _isUpdating = false;
  bool _isBookmarked = false;
  String? _currentUserId;
  List<BookModel> _similarBooks = [];
  bool _isLoadingSimilarBooks = true;
  bool _isOwned = false;
  bool _isCheckingOwnership = true;

  // Apple IAP state
  ProductDetails? _iapProduct;
  bool _isLoadingProduct = false;
  bool _iapInitialized = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _refreshBookData();
    _loadBookmarkStatus();
    _markBookAsViewed();
    _loadSimilarBooks();
    _checkOwnership();
    _initializeIAP();
  }

  @override
  void dispose() {
    AppleIAPService.dispose();
    super.dispose();
  }

  /// Initialize Apple IAP for iOS
  Future<void> _initializeIAP() async {
    if (!Platform.isIOS) return;

    try {
      final initialized = await AppleIAPService.initialize();
      if (mounted) {
        setState(() {
          _iapInitialized = initialized;
        });
      }

      if (initialized) {
        // Set up purchase callbacks
        AppleIAPService.onPurchaseComplete = _handleIAPPurchaseComplete;
        AppleIAPService.onPurchaseError = _handleIAPPurchaseError;

        // Load product details
        await _loadIAPProduct();
      }
    } catch (e) {
      print('Error initializing IAP: $e');
    }
  }

  /// Load IAP product details for this book
  Future<void> _loadIAPProduct() async {
    if (!Platform.isIOS || _book.price == 0) return;

    setState(() {
      _isLoadingProduct = true;
    });

    try {
      // Use price tier instead of book ID
      final productId = AppleIAPService.priceToProductId(_book.price);
      final product = await AppleIAPService.getProduct(productId);

      if (mounted) {
        setState(() {
          _iapProduct = product;
          _isLoadingProduct = false;
        });
      }

      if (product == null) {
        print('⚠️ Product not found in App Store: $productId');
        print('Make sure you created price tier products in App Store Connect');
      }
    } catch (e) {
      print('Error loading IAP product: $e');
      if (mounted) {
        setState(() {
          _isLoadingProduct = false;
        });
      }
    }
  }

  /// Handle successful IAP purchase
  void _handleIAPPurchaseComplete(PurchaseDetails purchase) async {
    if (!mounted) return;

    try {
      // Get receipt data
      final receipt = await AppleIAPService.getReceiptData(purchase);

      // Add to Firebase
      await PurchaseService.addPurchasedBookFromIAP(
        _currentUserId!,
        _book.id,
        transactionId: purchase.purchaseID ?? 'unknown',
        receipt: receipt,
        amount: _book.price,
        purchaseDate: DateTime.now(),
      );

      if (mounted) {
        await _checkOwnership();
        CustomToast.showSuccess(
          context,
          'Purchase successful! "${_book.title}" added to your library.',
        );
      }
    } catch (e) {
      print('Error processing IAP purchase: $e');
      if (mounted) {
        CustomToast.showError(context, 'Error processing purchase: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  /// Handle IAP purchase error
  void _handleIAPPurchaseError(String error) {
    if (!mounted) return;

    setState(() {
      _isPurchasing = false;
    });

    if (error != 'Purchase canceled') {
      CustomToast.showError(context, error);
    }
  }

  Future<void> _checkOwnership() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      try {
        final isOwned = await PurchaseService.isBookOwned(
          _currentUserId!,
          _book.id,
        );
        if (mounted) {
          setState(() {
            // Only mark as owned if explicitly in purchased list (not automatically for free books)
            _isOwned = isOwned;
            _isCheckingOwnership = false;
          });
        }
      } catch (e) {
        print('Error checking ownership: $e');
        if (mounted) {
          setState(() {
            // On error, don't assume owned
            _isOwned = false;
            _isCheckingOwnership = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          // Not logged in, don't assume owned
          _isOwned = false;
          _isCheckingOwnership = false;
        });
      }
    }
  }

  bool _isPurchasing = false;

  Future<void> _handlePurchase() async {
    if (_currentUserId == null) {
      CustomToast.showError(context, 'Please login to purchase books');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      CustomToast.showError(context, 'Please login to purchase books');
      return;
    }

    // If book is free (price == 0), show confirmation dialog
    if (_book.price == 0) {
      _showFreeBookClaimDialog();
      return;
    }

    // For paid books, check platform
    setState(() {
      _isPurchasing = true;
    });

    try {
      // iOS: Use Apple In-App Purchase
      if (Platform.isIOS) {
        if (!_iapInitialized) {
          throw Exception('Apple IAP not initialized');
        }

        if (_iapProduct == null) {
          throw Exception(
            'Product not found in App Store. Please make sure you created price tier: ${AppleIAPService.priceToProductId(_book.price)}',
          );
        }

        // Start IAP purchase flow using price tier
        await AppleIAPService.purchaseBookByPrice(_book.price);

        // Purchase result will be handled by callbacks
        // _handleIAPPurchaseComplete or _handleIAPPurchaseError
        // We do NOT set _isPurchasing = false here because it should stay
        // until the callback is triggered.
        return;
      }

      // Android/Web: Use Stripe payment flow
      final paymentResult = await StripeService.startPayment(
        bookId: _book.id,
        bookTitle: _book.title,
        price: _book.price,
        userId: _currentUserId!,
        userEmail: authState.user.email,
      );

      if (!mounted) return;

      if (paymentResult != null && paymentResult['success'] == true) {
        // Payment successful
        final paymentId = paymentResult['paymentId'] as String?;
        final transactionId = paymentResult['transactionId'] as String?;
        final amount = paymentResult['amount'] as double?;

        await PurchaseService.addPurchasedBook(
          _currentUserId!,
          _book.id,
          paymentId:
              paymentId ?? 'stripe_${DateTime.now().millisecondsSinceEpoch}',
          transactionId: transactionId,
          amount: amount ?? _book.price,
          purchaseDate: DateTime.now(),
        );

        if (mounted) {
          await _checkOwnership();
          CustomToast.showSuccess(
            context,
            'Purchase successful! "${_book.title}" added to your library.',
          );
        }
      } else {
        final error = paymentResult?['error'] as String? ?? 'Payment cancelled';
        if (mounted) {
          CustomToast.showError(context, error);
        }
      }

      // Reset for non-iOS platforms
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error processing purchase: $e');
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  void _showFreeBookClaimDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Claim Free Book',
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            'Would you like to add "${_book.title}" to your library for free?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _claimFreeBook();
              },
              child: Text(
                'Claim',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _claimFreeBook() async {
    if (_currentUserId == null) {
      CustomToast.showError(context, 'Please login to claim books');
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      // Add free book to purchased books in Firebase
      await PurchaseService.addPurchasedBook(
        _currentUserId!,
        _book.id,
        paymentId: 'free_${DateTime.now().millisecondsSinceEpoch}',
        transactionId: null,
        amount: 0.0,
        purchaseDate: DateTime.now(),
      );

      if (mounted) {
        await _checkOwnership();
        CustomToast.showSuccess(
          context,
          'Book claimed successfully! "${_book.title}" added to your library.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error claiming book: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  void _markBookAsViewed() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      ViewedBooksService.markBookAsViewed(
        userId: authState.user.id,
        bookId: _book.id,
      ).then((_) {
        // Refresh book data to get updated view count
        if (mounted) {
          _refreshBookData();
        }
      });
    }
  }

  void _loadBookmarkStatus() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      // Listen to bookmark status changes
      BookmarkService.isBookmarkedStream(
        userId: _currentUserId!,
        bookId: _book.id,
      ).listen((isBookmarked) {
        if (mounted) {
          setState(() {
            _isBookmarked = isBookmarked;
          });
        }
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentUserId == null) {
      CustomToast.showError(context, 'Please login to bookmark books');
      return;
    }

    try {
      final newStatus = await BookmarkService.toggleBookmark(
        userId: _currentUserId!,
        bookId: _book.id,
        book: _book,
      );

      if (mounted) {
        CustomToast.showSuccess(
          context,
          newStatus ? 'Book added to bookmarks' : 'Book removed from bookmarks',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error updating bookmark: $e');
      }
    }
  }

  Future<void> _refreshBookData() async {
    try {
      final updatedBook = await BookService.getBookById(widget.book.id);
      if (updatedBook != null && mounted) {
        final categoryChanged = _book.category != updatedBook.category;
        setState(() {
          _book = updatedBook;
        });
        // Reload similar books if category changed
        if (categoryChanged) {
          _loadSimilarBooks();
        }
      }
    } catch (e) {
      print('Error refreshing book data: $e');
    }
  }

  Future<void> _loadSimilarBooks() async {
    try {
      setState(() {
        _isLoadingSimilarBooks = true;
      });

      // Get all published books
      final booksStream = BookService.getAllPublishedBooks();
      await booksStream.first.then((allBooks) {
        if (!mounted) return;

        // Filter out the current book
        final otherBooks = allBooks
            .where((book) => book.id != _book.id)
            .toList();

        // Separate books by category match
        final sameCategoryBooks = otherBooks
            .where((book) => book.category == _book.category)
            .toList();
        final differentCategoryBooks = otherBooks
            .where((book) => book.category != _book.category)
            .toList();

        // Prioritize same category, then add others to reach 5
        List<BookModel> similarBooks = [];
        similarBooks.addAll(sameCategoryBooks.take(5));

        if (similarBooks.length < 5) {
          final remaining = 5 - similarBooks.length;
          similarBooks.addAll(differentCategoryBooks.take(remaining));
        }

        setState(() {
          _similarBooks = similarBooks;
          _isLoadingSimilarBooks = false;
        });
      });
    } catch (e) {
      print('Error loading similar books: $e');
      if (mounted) {
        setState(() {
          _isLoadingSimilarBooks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: SizeCons.getHeight(context) * 0.9,
              child: Stack(
                children: [
                  // Blurred Background
                  Container(
                    height: 432.h,
                    width: double.infinity,
                    color: AppColors.boxClr,
                    child: _book.coverImageUrl.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              _book.coverImageUrl.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: _book.coverImageUrl,
                                      width: double.infinity,
                                      height: 432.h,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          color: AppColors.boxClr,
                                        );
                                      },
                                      memCacheWidth: 800,
                                      memCacheHeight: 864,
                                    )
                                  : Image.asset(
                                      _book.coverImageUrl,
                                      width: double.infinity,
                                      height: 432.h,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: AppColors.boxClr,
                                            );
                                          },
                                    ),
                              BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          )
                        : BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeBack(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isAdmin =
                                state is Authenticated &&
                                state.user.role == 'admin';
                            if (isAdmin) {
                              // Show Edit button for admin
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditBookScreen(book: _book),
                                    ),
                                  );
                                  // Refresh book data when returning from edit screen
                                  if (result == true || mounted) {
                                    await _refreshBookData();
                                  }
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              );
                            } else {
                              // Show Bookmark for regular users
                              return GestureDetector(
                                onTap: _toggleBookmark,
                                child: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  color: _isBookmarked
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                  size: 20.sp,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Book Cover and Info
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: SizeCons.getHeight(context) * 0.65,
                      decoration: BoxDecoration(
                        color: AppColors.bgClr,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50.r),
                          topRight: Radius.circular(50.r),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 90.h),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40.w),
                                child: Text(
                                  _book.title,
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              8.verticalSpace,
                              // Author
                              Text(
                                _book.author,
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 14.sp,
                                ),
                              ),
                              8.verticalSpace,
                              // Price - Show "Owned" badge if book is owned
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (_isCheckingOwnership) {
                                    return SizedBox(height: 30.h);
                                  } else if (_isOwned) {
                                    return Column(
                                      children: [
                                        // "Owned" text
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            border: Border.all(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          child: Text(
                                            'OWNED',
                                            style: AppTextStyles.lufgaMedium
                                                .copyWith(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 08.sp,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                              20.verticalSpace,
                              // Action Buttons - Admin always sees Read/Listen, regular users see purchase if not owned
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isAdmin =
                                      state is Authenticated &&
                                      state.user.role == 'admin';

                                  // Admin always sees Read/Listen buttons
                                  if (isAdmin) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_book.type == BookType.ebook)
                                          GestureDetector(
                                            onTap: () {
                                              AppRouter.routeTo(
                                                context,
                                                ReadingScreen(book: _book),
                                              );
                                            },
                                            child: _buildActionButton(
                                              icon: Icons.menu_book,
                                              text: 'Read Book',
                                            ),
                                          ),
                                        if (_book.type == BookType.audiobook)
                                          GestureDetector(
                                            onTap: () {
                                              AppRouter.routeTo(
                                                context,
                                                ListenScreen(book: _book),
                                              );
                                            },
                                            child: _buildActionButton(
                                              icon: Icons.headphones,
                                              text: 'Listen Book',
                                            ),
                                          ),
                                      ],
                                    );
                                  }

                                  // Regular users
                                  if (_isCheckingOwnership) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                      ),
                                    );
                                  } else if (_isOwned) {
                                    // Only show Read/Listen if book is explicitly owned
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_book.type == BookType.ebook)
                                          GestureDetector(
                                            onTap: () {
                                              AppRouter.routeTo(
                                                context,
                                                ReadingScreen(book: _book),
                                              );
                                            },
                                            child: _buildActionButton(
                                              icon: Icons.menu_book,
                                              text: 'Read Book',
                                            ),
                                          ),
                                        if (_book.type == BookType.audiobook)
                                          GestureDetector(
                                            onTap: () {
                                              AppRouter.routeTo(
                                                context,
                                                ListenScreen(book: _book),
                                              );
                                            },
                                            child: _buildActionButton(
                                              icon: Icons.headphones,
                                              text: 'Listen Book',
                                            ),
                                          ),
                                      ],
                                    );
                                  } else {
                                    // Show purchase button if not owned
                                    if (_isPurchasing) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24.w,
                                            height: 24.w,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          8.horizontalSpace,
                                          Text(
                                            'Processing...',
                                            style: AppTextStyles.regular
                                                .copyWith(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey,
                                                ),
                                          ),
                                          if (!Platform.isIOS) ...[
                                            8.horizontalSpace,
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isPurchasing = false;
                                                });
                                              },
                                              child: Text(
                                                'Cancel',
                                                style: AppTextStyles.regular
                                                    .copyWith(
                                                      fontSize: 14.sp,
                                                      color: Colors.red,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    }
                                    // Show "Free Claim" for free books, "Purchase" for paid books
                                    return Column(
                                      children: [
                                        if (_book.price > 0) ...[
                                          Text(
                                            Platform.isIOS &&
                                                    _iapProduct != null
                                                ? _iapProduct!.price
                                                : '\$${(_book.price).toStringAsFixed(2)}',
                                            style: AppTextStyles.lufgaMedium
                                                .copyWith(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 24.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          12.verticalSpace,
                                        ],
                                        GestureDetector(
                                          onTap: _handlePurchase,
                                          child: _buildActionButton(
                                            icon: _book.price == 0
                                                ? Icons.card_giftcard
                                                : Icons.shopping_cart,
                                            text: _book.price == 0
                                                ? 'Free Claim'
                                                : _getPurchaseButtonText(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),

                              // Content Sections
                              Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Duration Section
                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) {
                                        final isAdmin =
                                            state is Authenticated &&
                                            state.user.role == 'admin';
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // Row(
                                            //   children: [
                                            //     Icon(
                                            //       Icons.access_time,
                                            //       color: AppColors.primaryColor,
                                            //       size: 18.sp,
                                            //     ),
                                            //     5.horizontalSpace,
                                            //     Text(
                                            //       '${_book.readTime} min',
                                            //       style: AppTextStyles.medium
                                            //           .copyWith(
                                            //             color: AppColors
                                            //                 .primaryColor,
                                            //             fontSize: 14.sp,
                                            //           ),
                                            //     ),
                                            //   ],
                                            // ),
                                            if (isAdmin)
                                              Row(
                                                children: [
                                                  Text(
                                                    'Published: ',
                                                    style: AppTextStyles.medium
                                                        .copyWith(
                                                          color: Colors.white,
                                                          fontSize: 14.sp,
                                                        ),
                                                  ),
                                                  8.horizontalSpace,
                                                  CustomSwitch(
                                                    value: _book.isPublished,
                                                    onChanged: _isUpdating
                                                        ? null
                                                        : (value) {
                                                            _handlePublishToggle(
                                                              value,
                                                              isAdmin,
                                                            );
                                                          },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                    16.verticalSpace,

                                    // About this Book Section
                                    Text(
                                      'About this Book',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    8.verticalSpace,
                                    Text(
                                      _book.description,
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.grey[300],
                                        fontSize: 14.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                    30.verticalSpace,

                                    // Similar Books Section
                                    Text(
                                      'Similar Books',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    16.verticalSpace,
                                    _isLoadingSimilarBooks
                                        ? SizedBox(
                                            height: 200.h,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          )
                                        : _similarBooks.isEmpty
                                        ? SizedBox(
                                            height: 200.h,
                                            child: Center(
                                              child: Text(
                                                'No similar books found',
                                                style: AppTextStyles.regular
                                                    .copyWith(
                                                      color: Colors.grey[400],
                                                      fontSize: 14.sp,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            height: 200.h,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _similarBooks.length,
                                              itemBuilder: (context, index) {
                                                final book =
                                                    _similarBooks[index];
                                                return GestureDetector(
                                                  onTap: () {
                                                    AppRouter.routeTo(
                                                      context,
                                                      BookDetailScreen(
                                                        book: book,
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 140.w,
                                                    margin: EdgeInsets.only(
                                                      right: 16.w,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.r,
                                                              ),
                                                          child: Container(
                                                            height: 120.h,
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                book
                                                                    .coverImageUrl
                                                                    .isNotEmpty
                                                                ? (book.coverImageUrl
                                                                          .startsWith(
                                                                            'http',
                                                                          )
                                                                      ? CachedNetworkImage(
                                                                          imageUrl:
                                                                              book.coverImageUrl,
                                                                          width:
                                                                              double.infinity,
                                                                          height:
                                                                              120.h,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          progressIndicatorBuilder:
                                                                              (
                                                                                context,
                                                                                url,
                                                                                progress,
                                                                              ) => Container(
                                                                                width: double.infinity,
                                                                                height: 120.h,
                                                                                color: Colors.grey[800],
                                                                                child: Center(
                                                                                  child: CircularProgressIndicator(
                                                                                    value: progress.progress,
                                                                                    color: AppColors.primaryColor,
                                                                                    strokeWidth: 2,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                          errorWidget:
                                                                              (
                                                                                context,
                                                                                url,
                                                                                error,
                                                                              ) {
                                                                                return Container(
                                                                                  width: double.infinity,
                                                                                  height: 120.h,
                                                                                  color: Colors.grey[800],
                                                                                  child: Icon(
                                                                                    Icons.image_not_supported,
                                                                                    color: Colors.grey[600],
                                                                                    size: 30.sp,
                                                                                  ),
                                                                                );
                                                                              },
                                                                          fadeInDuration: Duration(
                                                                            milliseconds:
                                                                                300,
                                                                          ),
                                                                          memCacheWidth:
                                                                              280,
                                                                          memCacheHeight:
                                                                              240,
                                                                        )
                                                                      : Image.asset(
                                                                          book.coverImageUrl,
                                                                          width:
                                                                              double.infinity,
                                                                          height:
                                                                              120.h,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder:
                                                                              (
                                                                                context,
                                                                                error,
                                                                                stackTrace,
                                                                              ) {
                                                                                return Container(
                                                                                  width: double.infinity,
                                                                                  height: 120.h,
                                                                                  color: Colors.grey[800],
                                                                                  child: Icon(
                                                                                    Icons.image_not_supported,
                                                                                    color: Colors.grey[600],
                                                                                    size: 30.sp,
                                                                                  ),
                                                                                );
                                                                              },
                                                                        ))
                                                                : Image.asset(
                                                                    'assets/tempImg/temp1.png',
                                                                    width: double
                                                                        .infinity,
                                                                    height:
                                                                        120.h,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                          ),
                                                        ),
                                                        8.verticalSpace,
                                                        Text(
                                                          book.title,
                                                          style: AppTextStyles
                                                              .medium
                                                              .copyWith(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12.sp,
                                                              ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        4.verticalSpace,
                                                        Text(
                                                          book.author,
                                                          style: AppTextStyles
                                                              .regular
                                                              .copyWith(
                                                                color: Colors
                                                                    .grey[400],
                                                                fontSize: 10.sp,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        8.verticalSpace,
                                                        Builder(
                                                          builder: (context) {
                                                            final hasTime =
                                                                (book.type ==
                                                                        BookType
                                                                            .audiobook &&
                                                                    book.listenTime >
                                                                        0) ||
                                                                (book.type ==
                                                                        BookType
                                                                            .ebook &&
                                                                    book.readTime >
                                                                        0);
                                                            final hasViewCount =
                                                                book.viewCount >
                                                                0;

                                                            if (!hasTime &&
                                                                !hasViewCount) {
                                                              return SizedBox.shrink();
                                                            }

                                                            return Row(
                                                              children: [
                                                                if (book.type ==
                                                                    BookType
                                                                        .audiobook)
                                                                  if (book.listenTime >
                                                                      0) ...[
                                                                    Icon(
                                                                      Icons
                                                                          .headphones,
                                                                      color: Colors
                                                                          .grey[400],
                                                                      size:
                                                                          10.sp,
                                                                    ),
                                                                    2.horizontalSpace,
                                                                    Text(
                                                                      '${book.listenTime}m',
                                                                      style: AppTextStyles.regular.copyWith(
                                                                        color: Colors
                                                                            .grey[400],
                                                                        fontSize:
                                                                            10.sp,
                                                                      ),
                                                                    ),
                                                                    if (hasViewCount)
                                                                      8.horizontalSpace,
                                                                  ],
                                                                if (book.type ==
                                                                    BookType
                                                                        .ebook)
                                                                  if (book.readTime >
                                                                      0) ...[
                                                                    Icon(
                                                                      Icons
                                                                          .menu_book,
                                                                      color: Colors
                                                                          .grey[400],
                                                                      size:
                                                                          10.sp,
                                                                    ),
                                                                    2.horizontalSpace,
                                                                    Text(
                                                                      '${book.readTime}m',
                                                                      style: AppTextStyles.regular.copyWith(
                                                                        color: Colors
                                                                            .grey[400],
                                                                        fontSize:
                                                                            10.sp,
                                                                      ),
                                                                    ),
                                                                    if (hasViewCount)
                                                                      8.horizontalSpace,
                                                                  ],
                                                                if (hasViewCount) ...[
                                                                  Icon(
                                                                    Icons
                                                                        .visibility,
                                                                    color: Colors
                                                                        .grey[400],
                                                                    size: 10.sp,
                                                                  ),
                                                                  2.horizontalSpace,
                                                                  Text(
                                                                    '${book.viewCount}',
                                                                    style: AppTextStyles
                                                                        .regular
                                                                        .copyWith(
                                                                          color:
                                                                              Colors.grey[400],
                                                                          fontSize:
                                                                              10.sp,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                    20.verticalSpace,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 120.h),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          height: 159.h,
                          width: 159.w,
                          child: _book.coverImageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: _book.coverImageUrl,
                                  width: 159.w,
                                  height: 159.h,
                                  fit: BoxFit.contain,
                                  progressIndicatorBuilder:
                                      (context, url, progress) => Container(
                                        width: 159.w,
                                        height: 159.h,
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: progress.progress,
                                            color: AppColors.primaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      width: 159.w,
                                      height: 159.h,
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[600],
                                        size: 40.sp,
                                      ),
                                    );
                                  },
                                  fadeInDuration: Duration(milliseconds: 300),
                                  memCacheWidth: 318,
                                  memCacheHeight: 318,
                                )
                              : Image.asset(
                                  _book.coverImageUrl,
                                  width: 159.w,
                                  height: 159.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 159.w,
                                      height: 159.h,
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[600],
                                        size: 40.sp,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePublishToggle(bool newValue, bool isAdmin) {
    if (!isAdmin) return;

    final action = newValue ? 'publish' : 'unpublish';
    final actionCapitalized = newValue ? 'Publish' : 'Unpublish';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '$actionCapitalized Book',
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to $action "${_book.title}"?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'No',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _updatePublishStatus(newValue);
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePublishStatus(bool isPublished) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedBook = BookModel(
        id: _book.id,
        title: _book.title,
        author: _book.author,
        description: _book.description,
        coverImageUrl: _book.coverImageUrl,
        content: _book.content,
        pdfUrl: _book.pdfUrl,
        audioFileUrl: _book.audioFileUrl,
        chapters: _book.chapters,
        category: _book.category,
        type: _book.type,
        readTime: _book.readTime,
        listenTime: _book.listenTime,
        listenCount: _book.listenCount,
        viewCount: _book.viewCount,
        readCount: _book.readCount,
        listenedUserCount: _book.listenedUserCount,
        isPublished: isPublished,
        hasEverBeenPublished: _book.hasEverBeenPublished,
        createdAt: _book.createdAt,
        updatedAt: DateTime.now(),
      );

      await BookService.updateBook(_book.id, updatedBook);

      setState(() {
        _book = updatedBook;
        _isUpdating = false;
      });

      CustomToast.showSuccess(
        context,
        isPublished
            ? 'Book published successfully!'
            : 'Book unpublished successfully!',
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      CustomToast.showError(context, 'Error updating book status: $e');
    }
  }

  Widget _buildActionButton({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          8.horizontalSpace,
          Text(
            text,
            style: AppTextStyles.regular.copyWith(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Get purchase button text with appropriate pricing
  String _getPurchaseButtonText() {
    return 'Purchase';
  }
}
