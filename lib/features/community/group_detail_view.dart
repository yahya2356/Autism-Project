import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../shared/widgets/c_text.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'community_controller.dart';

class GroupDetailView extends GetView<CommunityController> {
  const GroupDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = controller.selectedGroup.value;
      if (group == null) {
        return const Scaffold(body: Center(child: Text('Group not found')));
      }

      return Scaffold(
        appBar: CustomAppBar(text: group.groupName, leadingIcon: true),
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(text: group.description, fontSize: 13, color: AppColors.textSecondary),
                  SizedBox(height: 8.h),
                  CText(
                    text: 'Members: ${group.totalMembers} • ${group.visibilityLabel} group',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Obx(() => !controller.isInSelectedGroup.value
                ? Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.orange),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: CText(
                            text: 'Join this group to view and create posts.',
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
            Expanded(
              child: Obx(() {
                if (!controller.isInSelectedGroup.value) {
                  final request = controller.joinRequestForGroup(group.groupId);
                  final hasPendingRequest = request?.status == 'pending';
                  return Center(
                    child: hasPendingRequest
                        ? Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.orange.withValues(alpha: 0.12),
                            ),
                            child: CText(
                              text: 'Your join request is pending approval.',
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => controller.submitJoinAction(group),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: Text(
                              group.isPrivate ? 'Request to Join Group' : 'Join Group',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  );
                }

                if (controller.selectedGroupPosts.isEmpty) {
                  return Center(
                    child: CText(
                      text: 'No group posts yet. Be the first parent to post.',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 90.h),
                  itemCount: controller.selectedGroupPosts.length,
                  itemBuilder: (context, index) {
                    final post = controller.selectedGroupPosts[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CText(text: post.content, fontSize: 14),
                          SizedBox(height: 6.h),
                          CText(
                            text: post.timestamp.toString().substring(0, 16),
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButton: Obx(() {
          if (!controller.isInSelectedGroup.value) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showCreatePostSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit),
            label: const Text('Create Post'),
          );
        }),
      );
    });
  }

  void _showCreatePostSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.groupPostController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Share with the group',
                hintText: 'Write a helpful update, question, or tip...',
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final posted = await controller.createSelectedGroupPost();
                  if (posted) {
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Post to Group'),
              ),
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
