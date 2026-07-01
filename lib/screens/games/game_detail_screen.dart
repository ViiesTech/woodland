import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/models/game_model.dart';
import 'package:the_woodlands_series/services/game_service.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'play_game_screen.dart';
import 'edit_game_screen.dart';
import 'word_search_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  List<GameModel> similarGames = [];
  StreamSubscription<List<GameModel>>? _gamesSubscription;
  GameModel? _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _loadSimilarGames();
  }

  void _loadSimilarGames() {
    _gamesSubscription = GameService.getAllGames().listen((games) {
      if (mounted) {
        setState(() {
          final List<GameModel> allExistingGames = [];
          
          // 1. Add local Mind Game
          allExistingGames.add(
            GameModel(
              id: 'mind_game',
              title: 'Mind Game',
              subtitle: 'Train your brain!',
              imageUrl: 'assets/tempImg/tempGame1.png',
              gameUrl: 'local',
              description: 'A local Woodland themed memory game. Train your mind by matching card pairs with minimal moves and time.',
              category: 'Woodland Series',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isPublished: true,
            ),
          );

          // 2. Add local Word Search Game
          allExistingGames.add(
            GameModel(
              id: 'word_search',
              title: 'Woodland Word Search',
              subtitle: 'Find hidden forest words!',
              imageUrl: 'assets/wordsearchgame/wordseach.png',
              gameUrl: 'local',
              description: 'Search for hidden woodland animal and plant names in the letter grid. Find all words before time runs out!',
              category: 'Woodland Series',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isPublished: true,
            ),
          );

          // 3. Add other games from Firebase
          for (var game in games) {
            if (game.id != 'mind_game' && game.id != 'word_search') {
              allExistingGames.add(game);
            }
          }

          // Filter out the current game
          final currentGame = _currentGame ?? widget.game;
          similarGames = allExistingGames
              .where((game) => game.id != currentGame.id)
              .toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _gamesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: Text(
          'Game Detail',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isAdmin =
                  state is Authenticated && state.user.role == 'admin';
              if (!isAdmin) return SizedBox.shrink();

              return IconButton(
                onPressed: () async {
                  final updatedGame = await Navigator.push<GameModel>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditGameScreen(game: _currentGame ?? widget.game),
                    ),
                  );

                  if (updatedGame != null) {
                    setState(() {
                      _currentGame = updatedGame;
                    });
                  }
                },
                icon: Icon(Icons.edit, color: Colors.white),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 500.h,
              child: Stack(
                children: [
                  // Blurred background for upper section
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              (_currentGame ?? widget.game).imageUrl.startsWith(
                                'http',
                              )
                              ? NetworkImage(
                                  (_currentGame ?? widget.game).imageUrl,
                                )
                              : AssetImage(
                                      (_currentGame ?? widget.game).imageUrl,
                                    )
                                    as ImageProvider,
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Fallback handled by errorBuilder if needed
                          },
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 2),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.7),
                                AppColors.bgClr,
                                AppColors.bgClr,
                              ],
                              stops: [0.0, 0.2, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 227.w,
                          height: 225.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20.r,
                                offset: Offset(0, 10.h),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child:
                                (_currentGame ?? widget.game).imageUrl
                                    .startsWith('http')
                                ? Image.network(
                                    (_currentGame ?? widget.game).imageUrl,
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[600],
                                          size: 60.sp,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Image.asset(
                                    (_currentGame ?? widget.game).imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[600],
                                          size: 60.sp,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        16.verticalSpace,

                        // Game title
                        SizedBox(
                          width: 350.w,
                          child: Text(
                            (_currentGame ?? widget.game).title,
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Game subtitle
                        if ((_currentGame ?? widget.game)
                            .subtitle
                            .isNotEmpty) ...[
                          8.verticalSpace,
                          SizedBox(
                            width: 350.w,
                            child: Text(
                              (_currentGame ?? widget.game).subtitle,
                              style: AppTextStyles.medium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],

                        16.verticalSpace,

                        PrimaryButton(
                          buttonWidth: 250.w,
                          title: 'Play Game',
                          onTap: () {
                            final game = _currentGame ?? widget.game;
                            if (game.id == 'word_search') {
                              AppRouter.routeTo(
                                context,
                                const WordSearchScreen(
                                  gameTitle: 'Woodland Word Search',
                                ),
                              );
                            } else if (game.gameUrl.isNotEmpty) {
                              AppRouter.routeTo(
                                context,
                                PlayGameScreen(
                                  gameUrl: game.gameUrl,
                                  gameTitle: game.title,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game URL not available'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        16.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lower section with normal background
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                color: AppColors.bgClr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    40.verticalSpace,

                    // Category
                    Builder(
                      builder: (context) {
                        final game = _currentGame ?? widget.game;
                        if (game.category.isEmpty) return SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.category,
                              style: AppTextStyles.medium.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                            8.verticalSpace,
                          ],
                        );
                      },
                    ),

                    // About this Game
                    Text(
                      'About this Game',
                      style: AppTextStyles.lufgaLarge.copyWith(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    16.verticalSpace,

                    // Description
                    Builder(
                      builder: (context) {
                        final game = _currentGame ?? widget.game;
                        return Text(
                          game.description.isNotEmpty
                              ? game.description
                              : 'No description available.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        );
                      },
                    ),

                    40.verticalSpace,

                    // More Games
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'More Games',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ],
                        ),
                        16.verticalSpace,
                        similarGames.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: Text(
                                  'No more games available',
                                  style: AppTextStyles.regular.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16.w,
                                      mainAxisSpacing: 16.h,
                                      childAspectRatio: 0.43,
                                    ),
                                itemCount: similarGames.length,
                                itemBuilder: (context, index) {
                                  final game = similarGames[index];
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
                      ],
                    ),

                    40.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
