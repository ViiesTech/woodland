import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
              _buildSectionContent(
                'At The Woodlands Series, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website.',
              ),
              24.verticalSpace,
              _buildSectionTitle('1. Information We Collect'),
              _buildSectionContent(
                'We collect information that you provide directly to us, including:\n\n'
                '• Personal Information: Name, email address, phone number, and payment information\n'
                '• Account Information: Username, password, and profile information\n'
                '• Usage Data: Information about how you use our application, including reading progress, bookmarks, and preferences\n'
                '• Device Information: Device type, operating system, unique device identifiers, and mobile network information',
              ),
              24.verticalSpace,
              _buildSectionTitle('2. How We Use Your Information'),
              _buildSectionContent(
                'We use the information we collect to:\n\n'
                '• Provide, maintain, and improve our services\n'
                '• Process transactions and send related information\n'
                '• Send you technical notices, updates, and support messages\n'
                '• Respond to your comments, questions, and requests\n'
                '• Monitor and analyze trends, usage, and activities\n'
                '• Personalize and improve your experience\n'
                '• Detect, prevent, and address technical issues',
              ),
              24.verticalSpace,
              _buildSectionTitle('3. Information Sharing and Disclosure'),
              _buildSectionContent(
                'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
                '• With your consent\n'
                '• To comply with legal obligations\n'
                '• To protect and defend our rights or property\n'
                '• With service providers who assist us in operating our application\n'
                '• In connection with a business transfer or merger',
              ),
              24.verticalSpace,
              _buildSectionTitle('4. Data Security'),
              _buildSectionContent(
                'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure.',
              ),
              24.verticalSpace,
              _buildSectionTitle('5. Data Retention'),
              _buildSectionContent(
                'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.',
              ),
              24.verticalSpace,
              _buildSectionTitle('6. Your Rights'),
              _buildSectionContent(
                'You have the right to:\n\n'
                '• Access and receive a copy of your personal data\n'
                '• Rectify inaccurate or incomplete data\n'
                '• Request deletion of your personal data\n'
                '• Object to processing of your personal data\n'
                '• Request restriction of processing\n'
                '• Data portability\n'
                '• Withdraw consent at any time',
              ),
              24.verticalSpace,
              _buildSectionTitle('7. Cookies and Tracking Technologies'),
              _buildSectionContent(
                'We use cookies and similar tracking technologies to track activity on our application and hold certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
              ),
              24.verticalSpace,
              _buildSectionTitle('8. Third-Party Services'),
              _buildSectionContent(
                'Our application may contain links to third-party websites or services that are not owned or controlled by us. We have no control over, and assume no responsibility for, the privacy policies or practices of any third-party services.',
              ),
              24.verticalSpace,
              _buildSectionTitle('9. Children\'s Privacy'),
              _buildSectionContent(
                'Our service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
              ),
              24.verticalSpace,
              _buildSectionTitle('10. Changes to This Privacy Policy'),
              _buildSectionContent(
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
              ),
              24.verticalSpace,
              _buildSectionTitle('11. Contact Us'),
              _buildSectionContent(
                'If you have any questions about this Privacy Policy, please contact us through the contact information provided in the application.',
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
      padding: EdgeInsets.only(top: isLastUpdated ? 0 : 12.h),
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

