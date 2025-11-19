import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/screens/games/game_detail_screen.dart';
import 'package:the_woodlands_series/screens/games/add_game_screen.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import '../../components/resource/app_assets.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../components/textfield/primary_textfield.dart';
import '../../components/utils/three_dot_loader.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/game_service.dart';
import '../../models/game_model.dart';
import '../../models/user_model.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final PageController _pageController = PageController(
    initialPage: 1000, // Start from middle for infinite scroll
    viewportFraction: 0.6, // Show more of side cards
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _currentIndex = 0;
  bool isAdmin = false;
  List<GameModel> featuredGames = [];
  bool _isLoadingGames = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadGames();
    _pageController.addListener(() {
      if (_pageController.hasClients && featuredGames.isNotEmpty) {
        setState(() {
          _currentIndex = _pageController.page!.round() % featuredGames.length;
        });
      }
    });
  }

  StreamSubscription<List<GameModel>>? _gamesSubscription;

  void _loadGames() {
    // Listen to games stream and update list without causing rebuilds during sliding
    _gamesSubscription = GameService.getAllGames().listen(
      (games) {
        if (mounted) {
          setState(() {
            featuredGames = games;
            _isLoadingGames = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingGames = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _gamesSubscription?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkUserRole() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        isAdmin = authState.user.role == 'admin';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.verticalSpace,

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Games',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Add Game Icon (only for admin)
                            if (isAdmin)
                              GestureDetector(
                                onTap: () {
                                  AppRouter.routeTo(context, AddGameScreen());
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 12.w),
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final user = state is Authenticated
                                    ? state.user
                                    : null;
                                return GestureDetector(
                                  onTap: () {
                                    AppRouter.routeTo(
                                      context,
                                      ProfileScreen(
                                        title: 'Profile',
                                        image: AppAssets.profileImg,
                                      ),
                                    );
                                  },
                                  child: _buildUserAvatar(user),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    20.verticalSpace,

                    // Search Bar
                    PrimaryTextField(
                      controller: _searchController,
                      hint: 'Title, author or keyword',
                      prefixIcon: Icon(Icons.search, size: 20.sp),
                      height: 55.h,
                      verticalPad: 10.h,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                    20.verticalSpace,
                  ],
                ),
              ),

              // Content based on search query
              if (_searchQuery.isEmpty) ...[
                // Featured Games Carousel
                _isLoadingGames
                    ? SizedBox(
                        height: 350.h,
                        child: Center(
                          child: ThreeDotLoader(
                            color: AppColors.primaryColor,
                            size: 12.w,
                            spacing: 8.w,
                          ),
                        ),
                      )
                    : featuredGames.isEmpty
                    ? SizedBox(
                        height: 350.h,
                        child: Center(
                          child: Text(
                            'No games available',
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 350.h,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount:
                              featuredGames.length * 2000, // For infinite scroll
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index % featuredGames.length;
                            });
                          },
                          itemBuilder: (context, index) {
                            final gameIndex = index % featuredGames.length;
                            final game = featuredGames[gameIndex];

                            return GestureDetector(
                              onTap: () {
                                AppRouter.routeTo(
                                  context,
                                  GameDetailScreen(game: game),
                                );
                              },
                              child: AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  double value = 0.0;
                                  if (_pageController.position.haveDimensions) {
                                    value =
                                        index.toDouble() -
                                        (_pageController.page ?? 0);
                                    value = (1 - (value.abs() * 0.3)).clamp(
                                      0.0,
                                      1.0,
                                    );
                                  } else {
                                    // If we don't have dimensions yet, use a default value
                                    value = index == 1000 ? 1.0 : 0.7;
                                  }

                                  final isCenter = value > 0.9;
                                  final isSide = value > 0.4 && !isCenter;
                                  final height = isCenter
                                      ? 280.h
                                      : isSide
                                      ? 220.h
                                      : 180.h;
                                  final scale = isCenter
                                      ? 1.0
                                      : isSide
                                      ? 0.85
                                      : 0.7;

                                  return Column(
                                    children: [
                                      Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          height: height,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                          ),
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: game.imageUrl
                                                      .startsWith('http')
                                                  ? NetworkImage(game.imageUrl)
                                                  : AssetImage(game.imageUrl)
                                                        as ImageProvider,
                                              fit: BoxFit.cover,
                                              onError:
                                                  (exception, stackTrace) {
                                                // Fallback to placeholder if image fails
                                              },
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius:
                                                    isCenter ? 20.r : 10.r,
                                                offset: Offset(
                                                  0,
                                                  isCenter ? 10.h : 5.h,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.8),
                                                ],
                                              ),
                                              // Glass effect overlay for side cards
                                              color: Colors.black.withOpacity(
                                                isCenter
                                                    ? 0.0
                                                    : isSide
                                                    ? 0.3
                                                    : 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      12.verticalSpace,
                                      // Title below the image
                                      Expanded(
                                        child: Text(
                                          game.title,
                                          style: AppTextStyles.lufgaLarge
                                              .copyWith(
                                            color: Colors.white,
                                            fontSize: isCenter ? 18.sp : 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                15.verticalSpace,
                // More Games Section
                _isLoadingGames || featuredGames.isEmpty
                    ? SizedBox.shrink()
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'New Release',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          16.verticalSpace,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16.w,
                                mainAxisSpacing: 16.h,
                                childAspectRatio: 0.45,
                              ),
                              itemCount: featuredGames.length > 6
                                  ? 6
                                  : featuredGames.length, // Show max 6 games
                              itemBuilder: (context, index) {
                                final game = featuredGames[index];
                                return GestureDetector(
                                  onTap: () {
                                    AppRouter.routeTo(
                                      context,
                                      GameDetailScreen(game: game),
                                    );
                                  },
                                  child: GlobalCard(
                                    title: game.title,
                                    author: game.subtitle,
                                    imageAsset: game.imageUrl,
                                    listenTime: '',
                                    readTime: '',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ] else ...[
                // Search Results
                StreamBuilder<List<GameModel>>(
                  key: ValueKey('games_search_${_searchQuery.trim().toLowerCase()}'),
                  stream: GameService.searchGames(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return SizedBox(
                        height: 400.h,
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
                        child: Center(
                          child: Text(
                            'Error loading games',
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      );
                    }

                    final games = snapshot.data ?? [];

                    if (games.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Center(
                          child: Text(
                            'No games found',
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Search Results',
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
                        16.verticalSpace,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16.w,
                              mainAxisSpacing: 16.h,
                              childAspectRatio: 0.45,
                            ),
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              final game = games[index];
                              return GestureDetector(
                                onTap: () {
                                  AppRouter.routeTo(
                                    context,
                                    GameDetailScreen(game: game),
                                  );
                                },
                                child: GlobalCard(
                                  title: game.title,
                                  author: game.subtitle,
                                  imageAsset: game.imageUrl,
                                  listenTime: '',
                                  readTime: '',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    // If user has a profile image, show it
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 37.h,
        height: 37.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(user.profileImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // If user has no image, show avatar with initials
    if (user != null) {
      return Container(
        width: 37.h,
        height: 37.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Fallback to default image
    return Container(
      width: 37.h,
      height: 37.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(AppAssets.profileImg),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }
}
