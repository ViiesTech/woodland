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

class EbookPage extends StatefulWidget {
  const EbookPage({super.key});

  @override
  State<EbookPage> createState() => _EbookPageState();
}

class _EbookPageState extends State<EbookPage> {
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
                ? BookService.getBooksByType(BookType.ebook)
                : BookService.searchBooks(_searchQuery, BookType.ebook),
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
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No ebooks available'
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
                      // Recent Searches Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Recent Searches',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                      16.verticalSpace,
                      SizedBox(
                        height: 200.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length > 6 ? 6 : books.length,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return Container(
                              margin: EdgeInsets.only(right: 16.w),
                              child: _buildBookCard(book),
                            );
                          },
                        ),
                      ),
                      26.verticalSpace,
                      // New Release Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'New Release',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                      16.verticalSpace,
                    ],
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
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return _buildBookCard(book);
                        },
                      ),
                    ),
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

  Widget _buildBookCard(BookModel book) {
    return GestureDetector(
      onTap: () {
        try {
          if (book.id.isEmpty) {
            print('Error: Book ID is empty');
            return;
          }
          AppRouter.routeTo(context, BookDetailScreen(book: book));
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
