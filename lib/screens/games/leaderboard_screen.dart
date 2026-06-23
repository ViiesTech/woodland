import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = '';
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1E15),
              Color(0xFF070B08),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: StreamBuilder<List<LeaderboardEntry>>(
                  stream: LeaderboardService.getTopPlayers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryColor),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading leaderboard',
                          style: AppTextStyles.medium.copyWith(color: Colors.white70),
                        ),
                      );
                    }

                    final players = snapshot.data ?? [];

                    if (players.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.military_tech_outlined, color: Colors.white30, size: 64.sp),
                            12.verticalSpace,
                            Text(
                              'No scores registered yet!\nBe the first to claim the top spot!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.medium.copyWith(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Split players into podium (top 3) and list (rest)
                    final podiumPlayers = players.take(3).toList();
                    final listPlayers = players.length > 3 ? players.sublist(3) : <LeaderboardEntry>[];

                    return Column(
                      children: [
                        16.verticalSpace,
                        _buildPodium(podiumPlayers),
                        24.verticalSpace,
                        Expanded(
                          child: _buildRankingsList(listPlayers, currentUserId),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Leaderboard',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.emoji_events, color: Colors.amber, size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> podium) {
    // We need at least one player to show a podium
    if (podium.isEmpty) return const SizedBox.shrink();

    // Map spots: 1st in center, 2nd on left, 3rd on right
    LeaderboardEntry? first = podium.isNotEmpty ? podium[0] : null;
    LeaderboardEntry? second = podium.length > 1 ? podium[1] : null;
    LeaderboardEntry? third = podium.length > 2 ? podium[2] : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumSpot(second, 2, 100.h, Colors.grey, const Color(0xFFC0C0C0)),
          12.horizontalSpace,

          // 1st Place (Center, Highest)
          if (first != null)
            _buildPodiumSpot(first, 1, 130.h, Colors.amber, const Color(0xFFFFD700)),
          12.horizontalSpace,

          // 3rd Place
          if (third != null)
            _buildPodiumSpot(third, 3, 85.h, Colors.brown, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(
    LeaderboardEntry player,
    int rank,
    double height,
    Color accentColor,
    Color metalColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with Glowing border
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: rank == 1 ? 75.w : 60.w,
              height: rank == 1 ? 75.w : 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: metalColor, width: rank == 1 ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipOval(
                child: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                    ? Image.network(player.profileImageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[850],
                        child: Icon(Icons.person, color: Colors.white60, size: rank == 1 ? 36.sp : 28.sp),
                      ),
              ),
            ),
            // Rank Badge
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: metalColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rank == 1 ? Colors.black : Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        8.verticalSpace,
        
        // Name
        SizedBox(
          width: 90.w,
          child: Text(
            player.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        4.verticalSpace,
        
        // Score
        Text(
          '${player.gamePoints} pts',
          style: AppTextStyles.medium.copyWith(
            color: accentColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        12.verticalSpace,

        // The Podium Base
        Container(
          width: 95.w,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                metalColor.withOpacity(0.2),
                metalColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
            border: Border.all(color: metalColor.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Icon(
              Icons.military_tech,
              color: metalColor.withOpacity(0.5),
              size: rank == 1 ? 36.sp : 24.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(List<LeaderboardEntry> list, String currentUserId) {
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: list.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
        itemBuilder: (context, index) {
          final player = list[index];
          final rank = index + 4; // Podium is top 3, so list starts at rank 4
          final isCurrentUser = player.userId == currentUserId;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isCurrentUser ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: isCurrentUser 
                  ? Border.all(color: AppColors.primaryColor.withOpacity(0.3)) 
                  : null,
            ),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 30.w,
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: isCurrentUser ? AppColors.primaryColor : Colors.white60,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Avatar
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentUser ? AppColors.primaryColor : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                        ? Image.network(player.profileImageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[850],
                            child: const Icon(Icons.person, color: Colors.white54, size: 20),
                          ),
                  ),
                ),
                16.horizontalSpace,

                // Name
                Expanded(
                  child: Text(
                    player.userName,
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Score
                Text(
                  '${player.gamePoints} pts',
                  style: AppTextStyles.medium.copyWith(
                    color: isCurrentUser ? AppColors.primaryColor : Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
