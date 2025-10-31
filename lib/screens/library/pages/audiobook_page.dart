import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';

class AudiobookPage extends StatefulWidget {
  const AudiobookPage({super.key});

  @override
  State<AudiobookPage> createState() => _AudiobookPageState();
}

class _AudiobookPageState extends State<AudiobookPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: PrimaryTextField(
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
        ),
        16.verticalSpace,
        Expanded(
          child: StreamBuilder<List<BookModel>>(
            stream: _searchQuery.isEmpty
                ? BookService.getBooksByType(BookType.audiobook)
                : BookService.searchBooks(_searchQuery, BookType.audiobook),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: ThreeDotLoader(
                    color: AppColors.primaryColor,
                    size: 12.w,
                    spacing: 8.w,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading audiobooks',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }

              final books = snapshot.data ?? [];

              if (books.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No audiobooks available'
                        : 'No books found',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searchQuery.isEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Trending Audio Books',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                      16.verticalSpace,
                    ],
                    // Audiobooks List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _buildAudiobookItem(book);
                      },
                    ),
                    if (_searchQuery.isEmpty) ...[
                      16.verticalSpace,
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Suggested for you',
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
                          itemCount: books.length > 6 ? 6 : books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return _buildBookCard(book);
                          },
                        ),
                      ),
                    ],
                    26.verticalSpace,
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudiobookItem(BookModel book) {
    return GestureDetector(
      onTap: () {
        try {
          if (book.id.isEmpty) {
            print('Error: Book ID is empty');
            return;
          }
          AppRouter.routeTo(
            context,
            BookDetailScreen(book: book),
          );
        } catch (e) {
          print('Error navigating to book detail: $e');
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: book.coverImageUrl.startsWith('http')
                      ? NetworkImage(book.coverImageUrl) as ImageProvider
                      : AssetImage(book.coverImageUrl),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 16.w),

            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${book.listenTime} min',
                    style: AppTextStyles.regular.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 12.sp,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    book.title,
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.verticalSpace,
                  Text(
                    book.author,
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play button
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.play_arrow,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(BookModel book) {
    return GestureDetector(
      onTap: () {
        try {
          if (book.id.isEmpty) {
            print('Error: Book ID is empty');
            return;
          }
          AppRouter.routeTo(
            context,
            BookDetailScreen(book: book),
          );
        } catch (e) {
          print('Error navigating to book detail: $e');
        }
      },
      child: GlobalCard(
        title: book.title,
        author: book.author,
        imageAsset: book.coverImageUrl,
        listenTime: '${book.listenTime}m',
        readTime: '${book.readTime}m',
      ),
    );
  }
}
