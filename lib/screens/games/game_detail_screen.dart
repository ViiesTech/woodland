import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/models/game_model.dart';
import 'package:the_woodlands_series/services/game_service.dart';
import 'play_game_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  List<GameModel> similarGames = [];
  StreamSubscription<List<GameModel>>? _gamesSubscription;

  @override
  void initState() {
    super.initState();
    _loadSimilarGames();
  }

  void _loadSimilarGames() {
    // Load games from the same category, excluding the current game
    _gamesSubscription = GameService.getAllGames().listen((games) {
      if (mounted) {
        setState(() {
          similarGames = games
              .where(
                (game) =>
                    game.id != widget.game.id &&
                    game.category == widget.game.category,
              )
              .take(6)
              .toList();

          // If not enough games in same category, fill with other games
          if (similarGames.length < 6) {
            final otherGames = games
                .where(
                  (game) =>
                      game.id != widget.game.id &&
                      !similarGames.any((g) => g.id == game.id),
                )
                .take(6 - similarGames.length)
                .toList();
            similarGames.addAll(otherGames);
          }
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
                          image: widget.game.imageUrl.startsWith('http')
                              ? NetworkImage(widget.game.imageUrl)
                              : AssetImage(widget.game.imageUrl)
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
                            child: widget.game.imageUrl.startsWith('http')
                                ? Image.network(
                                    widget.game.imageUrl,
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
                                    widget.game.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        16.verticalSpace,

                        // Game title
                        SizedBox(
                          width: 350.w,
                          child: Text(
                            widget.game.title,
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
                        if (widget.game.subtitle.isNotEmpty) ...[
                          8.verticalSpace,
                          SizedBox(
                            width: 350.w,
                            child: Text(
                              widget.game.subtitle,
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
                            if (widget.game.gameUrl.isNotEmpty) {
                              AppRouter.routeTo(
                                context,
                                PlayGameScreen(
                                  gameUrl: widget.game.gameUrl,
                                  gameTitle: widget.game.title,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
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
                    if (widget.game.category.isNotEmpty)
                      Text(
                        widget.game.category,
                        style: AppTextStyles.medium.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 14.sp,
                        ),
                      ),

                    if (widget.game.category.isNotEmpty) 8.verticalSpace,

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
                    Text(
                      widget.game.description.isNotEmpty
                          ? widget.game.description
                          : 'No description available.',
                      style: AppTextStyles.regular.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),

                    40.verticalSpace,

                    // Similar Games
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Similar Games',
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
                                  'No similar games available',
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
