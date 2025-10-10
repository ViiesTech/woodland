import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/screens/games/game_detail_screen.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import '../../components/resource/app_assets.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../components/textfield/primary_textfield.dart';

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
  int selectedCategoryIndex = 0;

  int _currentIndex = 0;

  final List<Map<String, String>> categories = [
    {'title': 'Trending', 'icon': AppAssets.fireIcon},
    {'title': 'Quick Games', 'icon': AppAssets.readIcon},
    {'title': 'Simulation', 'icon': AppAssets.headphoneIcon},
  ];

  final List<Map<String, dynamic>> featuredGames = [
    {
      'title': 'FORTNITE',
      'subtitle': 'The Impervious Forest',
      'image': AppAssets.tempGame2,
      'color': Colors.blue,
    },
    {
      'title': 'MINECRAFT',
      'subtitle': 'Blocky Adventures',
      'image': AppAssets.tempGame1,
      'color': Colors.green,
    },
    {
      'title': 'ANIME FIGHTER',
      'subtitle': 'Epic Battles',
      'image': AppAssets.tempGame3,
      'color': Colors.purple,
    },
  ];

  final List<Map<String, String>> trendingBooks = [
    {
      'title': 'A PIRATE SCENT OF A LADY ORCHARD 2',
      'author': 'Mark McAllister',
      'imageAsset': AppAssets.tempGame4,
      'listenTime': '5m',
      'readTime': '8m',
    },
    {
      'title': 'THE ENCHANTED FOREST ADVENTURE',
      'author': 'Sarah Johnson',
      'imageAsset': AppAssets.tempGame5,
      'listenTime': '7m',
      'readTime': '12m',
    },
    {
      'title': 'MYSTERY OF THE DARK WOODS',
      'author': 'David Wilson',
      'imageAsset': AppAssets.tempGame6,
      'listenTime': '4m',
      'readTime': '6m',
    },
    {
      'title': 'THE LOST TREASURE HUNT',
      'author': 'Emily Brown',
      'imageAsset': AppAssets.tempGame4,
      'listenTime': '9m',
      'readTime': '15m',
    },
    {
      'title': 'FANTASY REALM CHRONICLES',
      'author': 'Michael Davis',
      'imageAsset': AppAssets.tempGame5,
      'listenTime': '6m',
      'readTime': '10m',
    },
    {
      'title': 'ADVENTURE IN THE MOUNTAINS',
      'author': 'Lisa Anderson',
      'imageAsset': AppAssets.tempGame6,
      'listenTime': '8m',
      'readTime': '14m',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentIndex = _pageController.page!.round() % featuredGames.length;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeTo(
                              context,
                              ProfileScreen(
                                title: 'Profile',
                                image: AppAssets.profileImg,
                              ),
                            );
                          },
                          child: Container(
                            width: 37.h,
                            height: 37.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(AppAssets.profileImg),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    20.verticalSpace,

                    // Search Bar
                    PrimaryTextField(
                      hint: 'Search Chat',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20.sp,
                        color: Colors.grey[600],
                      ),

                      height: 50.h,
                      verticalPad: 10.h,
                      fillColor: AppColors.boxClr,
                    ),

                    20.verticalSpace,
                  ],
                ),
              ),

              // Category Filters
              SizedBox(
                height: 45.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.boxClr
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              categories[index]['icon']!,
                              height: 18.h,
                              colorFilter: ColorFilter.mode(
                                isSelected ? Colors.white : Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            5.horizontalSpace,
                            Text(
                              categories[index]['title']!,
                              style: AppTextStyles.medium.copyWith(
                                color: isSelected ? Colors.white : Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              30.verticalSpace,

              // Featured Games Carousel
              SizedBox(
                height: 350.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: featuredGames.length * 2000, // For infinite scroll
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index % featuredGames.length;
                    });
                  },
                  itemBuilder: (context, index) {
                    final gameIndex = index % featuredGames.length;
                    final game = featuredGames[gameIndex];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_pageController.position.haveDimensions) {
                          value =
                              index.toDouble() - (_pageController.page ?? 0);
                          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
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

                        return GestureDetector(
                          onTap: () {
                            AppRouter.routeTo(
                              context,
                              GameDetailScreen(
                                title: game['title'],
                                image: game['image'],
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Transform.scale(
                                scale: scale,
                                child: Container(
                                  height: height,
                                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(game['image']),
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: isCenter ? 20.r : 10.r,
                                        offset: Offset(
                                          0,
                                          isCenter ? 10.h : 5.h,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
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
                                  game['title'],
                                  style: AppTextStyles.lufgaLarge.copyWith(
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              15.verticalSpace,

              // More Games Section
              Column(
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
                        Text(
                          'View all',
                          style: AppTextStyles.medium.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 12.sp,
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.45,
                      ),
                      itemCount: trendingBooks.length,
                      itemBuilder: (context, index) {
                        final book = trendingBooks[index];
                        return GlobalCard(
                          title: book['title']!,
                          author: book['author']!,
                          imageAsset: book['imageAsset']!,
                          listenTime: book['listenTime']!,
                          readTime: book['readTime']!,
                        );
                      },
                    ),
                  ),
                ],
              ),

              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
