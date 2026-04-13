import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/models/game_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/services/game_service.dart';
import 'package:the_woodlands_series/services/search_history_service.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/screens/games/game_detail_screen.dart';
import 'package:the_woodlands_series/components/button/bookmark_icon_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _currentUserId;
  List<String> _recentSearches = [];
  bool _isLoadingRecentSearches = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadRecentSearches();
    // Focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }
  }

  Future<void> _loadRecentSearches() async {
    setState(() {
      _isLoadingRecentSearches = true;
    });
    final searches = await SearchHistoryService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
        _isLoadingRecentSearches = false;
      });
    }
  }

  Future<void> _clearRecentSearches() async {
    await SearchHistoryService.clearRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }

  void _onSearchQueryChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // Reload recent searches when search is cleared
    if (value.trim().isEmpty) {
      _debounceTimer?.cancel();
      _loadRecentSearches();
      return;
    }
    
    // Debounce: Save search query after user stops typing for 1.5 seconds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && value.trim().isNotEmpty && value.trim().length >= 2) {
        SearchHistoryService.addSearchQuery(value.trim());
      }
    });
  }

  Future<void> _onSearchItemTap(String query) async {
    await SearchHistoryService.addSearchQuery(query);
    setState(() {
      _searchQuery = query;
      _searchController.text = query;
    });
    await _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryTextField(
                      controller: _searchController,
                      focus: _searchFocusNode,
                      hint: 'Title, author or keyword',
                      prefixIcon: Icon(Icons.search, size: 20.sp),
                      height: 55.h,
                      verticalPad: 10.h,
                      onChanged: _onSearchQueryChanged,
                    ),
                  ),
                  8.horizontalSpace,
                  GestureDetector(
                    onTap: () {
                      AppRouter.routeBack(context);
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.medium.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecentSearches,
                    child: Text(
                      'Clear',
                      style: AppTextStyles.medium.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            ..._recentSearches.map((search) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => _onSearchItemTap(search),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.white.withOpacity(0.5),
                            size: 20.sp,
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: Text(
                              search,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.3),
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ] else if (!_isLoadingRecentSearches) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'No recent searches',
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin =
            state is Authenticated && state.user.role == 'admin';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Books Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Text(
                  'Books',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
              ),
              StreamBuilder<List<BookModel>>(
                stream: isAdmin
                    ? BookService.searchAllBooks(_searchQuery, null)
                    : BookService.searchBooks(_searchQuery, null),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Center(
                        child: ThreeDotLoader(
                          color: AppColors.primaryColor,
                          size: 12.w,
                          spacing: 8.w,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Error loading books',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final books = snapshot.data ?? [];

                  if (books.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'No books found',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 200.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Container(
                          margin: EdgeInsets.only(right: 16.w),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await SearchHistoryService.addSearchQuery(
                                    _searchQuery,
                                  );
                                  if (mounted) {
                                    AppRouter.routeTo(
                                      context,
                                      BookDetailScreen(book: book),
                                    );
                                  }
                                },
                                child: GlobalCard(
                                  title: book.title,
                                  author: book.author,
                                  imageAsset: book.coverImageUrl,
                                  listenTime: '${book.listenTime}m',
                                  readTime: '${book.readTime}m',
                                  book: book,
                                ),
                              ),
                              if (_currentUserId != null)
                                Positioned(
                                  top: 4.h,
                                  right: 4.w,
                                  child: BookmarkIconButton(
                                    userId: _currentUserId!,
                                    book: book,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              26.verticalSpace,
              // Games Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'Games',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
              ),
              16.verticalSpace,
              StreamBuilder<List<GameModel>>(
                key: ValueKey('games_${_searchQuery.trim().toLowerCase()}'),
                stream: GameService.searchGames(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Center(
                        child: ThreeDotLoader(
                          color: AppColors.primaryColor,
                          size: 12.w,
                          spacing: 8.w,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Error loading games',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final games = snapshot.data ?? [];

                  if (games.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'No games found',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 200.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: games.length,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return Container(
                          margin: EdgeInsets.only(right: 16.w),
                          child: GestureDetector(
                            onTap: () async {
                              await SearchHistoryService.addSearchQuery(
                                _searchQuery,
                              );
                              if (mounted) {
                                AppRouter.routeTo(
                                  context,
                                  GameDetailScreen(game: game),
                                );
                              }
                            },
                            child: GlobalCard(
                              title: game.title,
                              author: game.subtitle,
                              imageAsset: game.imageUrl,
                              listenTime: '',
                              readTime: '',
                              book: null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              26.verticalSpace,
            ],
          ),
        );
      },
    );
  }
}

