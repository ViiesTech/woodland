import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.verticalSpace,
              _buildSectionTitle('1. Acceptance of Terms'),
              _buildSectionContent(
                'By accessing and using The Woodlands Series mobile application and website, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
              ),
              24.verticalSpace,
              _buildSectionTitle('2. Use License'),
              _buildSectionContent(
                'Permission is granted to temporarily download one copy of the materials on The Woodlands Series for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                '• Modify or copy the materials\n'
                '• Use the materials for any commercial purpose or for any public display\n'
                '• Attempt to decompile or reverse engineer any software contained in the application\n'
                '• Remove any copyright or other proprietary notations from the materials',
              ),
              24.verticalSpace,
              _buildSectionTitle('3. User Account'),
              _buildSectionContent(
                'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account or password. You must notify us immediately of any unauthorized use of your account.',
              ),
              24.verticalSpace,
              _buildSectionTitle('4. Content and Intellectual Property'),
              _buildSectionContent(
                'All content, including but not limited to text, graphics, logos, images, audio clips, digital downloads, and software, is the property of The Woodlands Series or its content suppliers and is protected by international copyright laws. The compilation of all content on this app is the exclusive property of The Woodlands Series.',
              ),
              24.verticalSpace,
              _buildSectionTitle('5. User Conduct'),
              _buildSectionContent(
                'You agree not to use the service to:\n\n'
                '• Violate any laws or regulations\n'
                '• Infringe upon the rights of others\n'
                '• Transmit any harmful, threatening, abusive, or offensive content\n'
                '• Interfere with or disrupt the service or servers\n'
                '• Attempt to gain unauthorized access to any portion of the service',
              ),
              24.verticalSpace,
              _buildSectionTitle('6. Purchases and Payments'),
              _buildSectionContent(
                'When you make a purchase through our service, you agree to provide current, complete, and accurate purchase and account information. All purchases are processed through secure payment gateways. Refunds are subject to our refund policy.',
              ),
              24.verticalSpace,
              _buildSectionTitle('7. Privacy'),
              _buildSectionContent(
                'Your use of the service is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding the collection and use of your personal information.',
              ),
              24.verticalSpace,
              _buildSectionTitle('8. Disclaimer'),
              _buildSectionContent(
                'The materials on The Woodlands Series are provided on an "as is" basis. The Woodlands Series makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
              ),
              24.verticalSpace,
              _buildSectionTitle('9. Limitations'),
              _buildSectionContent(
                'In no event shall The Woodlands Series or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on The Woodlands Series, even if The Woodlands Series or an authorized representative has been notified orally or in writing of the possibility of such damage.',
              ),
              24.verticalSpace,
              _buildSectionTitle('10. Revisions'),
              _buildSectionContent(
                'The Woodlands Series may revise these terms of service at any time without notice. By using this service, you are agreeing to be bound by the then current version of these terms of service.',
              ),
              24.verticalSpace,
              _buildSectionTitle('11. Contact Information'),
              _buildSectionContent(
                'If you have any questions about these Terms of Service, please contact us through the contact information provided in the application.',
              ),
              24.verticalSpace,
              _buildSectionContent(
                'Last updated: ${DateTime.now().year}',
                isLastUpdated: true,
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.lufgaMedium.copyWith(
        color: AppColors.primaryColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionContent(String content, {bool isLastUpdated = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Text(
        content,
        style: AppTextStyles.regular.copyWith(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14.sp,
          height: 1.6,
        ),
      ),
    );
  }
}

