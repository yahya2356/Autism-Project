import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/c_text.dart';
import '../../data/models/post_model.dart';
import 'community_controller.dart';
import '../../routes/app_pages.dart';

class FilteredPostsView extends GetView<CommunityController> {
  const FilteredPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        text: controller.selectedCategory.value?.name ?? "Posts",
        leadingIcon: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final posts = controller.filteredPosts;

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.post_add_outlined,
                        size: 64.sp,
                        color: AppColors.grey400,
                      ),
                      SizedBox(height: 16.h),
                      CText(
                        text: "No posts yet. Be the first to post!",
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshPosts,
                child: ListView.builder(
                  itemCount: posts.length,
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(Routes.POST_CREATION);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Create Post"),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final isAnonymous = post.hideName == true;
    final displayName = isAnonymous ? 'Anonymous Parent' : (post.authorName ?? "Parent");
    final authorImage = post.authorImage;
    final imageUrl = post.imageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.grey200,
                backgroundImage: !isAnonymous && (authorImage?.isNotEmpty ?? false)
                    ? NetworkImage(authorImage!)
                    : null,
                child: isAnonymous || !(authorImage?.isNotEmpty ?? false)
                    ? Icon(Icons.person, color: AppColors.grey500)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(
                      text: displayName,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    CText(
                      text: post.createdAt.toString().substring(0, 16),
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CText(
            text: post.title,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8.h),
          CText(
            text: post.description,
            fontSize: 14,
            color: AppColors.textPrimary,
            lineHeight: 1.5,
          ),
          if (imageUrl?.isNotEmpty ?? false) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              InkWell(
                onTap: () => Get.find<CommunityController>().likePost(post.id),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20.sp, color: AppColors.textSecondary),
                    SizedBox(width: 6.w),
                    CText(text: post.likesCount.toString(), fontSize: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
              SizedBox(width: 24.w),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 20.sp, color: AppColors.textSecondary),
                  SizedBox(width: 6.w),
                  CText(text: post.commentCount.toString(), fontSize: 14, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
