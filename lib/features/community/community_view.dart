import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../shared/widgets/c_text.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'community_controller.dart';
import 'filtered_posts_view.dart';
import 'group_detail_view.dart';

class CommunityView extends GetView<CommunityController> {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(text: 'Community Hub', leadingIcon: false),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateGroupSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Create Group'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search by group, location or condition',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: 'Discover'),
                  Tab(text: 'My Groups'),
                  Tab(text: 'Posts'),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: TabBarView(
                children: [
                  _groupListView(useMyGroups: false),
                  _groupListView(useMyGroups: true),
                  _buildPostsPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsPanel() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        _buildWelcomeCard(),
        SizedBox(height: 18.h),
        CText(
          text: 'Browse Categories',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 12.h),
        Obx(() {
          if (controller.categories.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: CText(
                  text: 'No categories available',
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              final postsCount = controller.getPostCountForCategory(category.id);
              return _categoryTile(
                title: category.name,
                subtitle: 'Join the discussion',
                postsCount: '$postsCount posts',
                iconEmoji: category.icon,
                onTap: () {
                  controller.selectCategory(category);
                  Get.to(() => const FilteredPostsView());
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _groupListView({required bool useMyGroups}) {
    return Obx(() {
      final groups = useMyGroups ? controller.myGroups : controller.visibleGroups;
      if (groups.isEmpty) {
        return Center(
          child: CText(
            text: useMyGroups ? 'You have not joined groups yet.' : 'No groups found.',
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 90.h),
        itemCount: groups.length,
        itemBuilder: (context, index) => _groupCard(groups[index]),
      );
    });
  }

  Widget _groupCard(dynamic group) {
    final instructions = group.instructions as List<String>;
    final issue = controller.getEligibilityIssue(group);

    return InkWell(
      onTap: () async {
        if (!controller.canAccessGroup(group)) {
          Get.snackbar(
            'Private Group',
            'You need to join and be approved before opening this private group.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        await controller.openGroup(group);
        Get.to(() => const GroupDetailView());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CText(
                    text: group.groupName,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _chip(group.visibilityLabel, group.isPrivate ? Colors.orange : Colors.green),
              ],
            ),
            SizedBox(height: 6.h),
            CText(text: group.description, fontSize: 13, color: AppColors.textSecondary),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('📍 ${group.locationCode}', AppColors.primary),
                _chip('👨‍👩‍👧 ${group.totalMembers}', Colors.blueGrey),
                if (group.minChildAge != null && group.maxChildAge != null)
                  _chip('Ages ${group.minChildAge}-${group.maxChildAge}', Colors.deepPurple),
              ],
            ),
            if (instructions.isNotEmpty) ...[
              SizedBox(height: 10.h),
              CText(text: 'Group instructions', fontSize: 13, fontWeight: FontWeight.bold),
              ...instructions.map(
                (i) => Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: CText(text: '• $i', fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            if (issue != null)
              CText(text: issue, fontSize: 12, color: Colors.red.shade400)
            else
              CText(text: 'Eligible to join', fontSize: 12, color: Colors.green.shade700),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.submitJoinAction(group),
                    icon: Icon(group.isPrivate ? Icons.lock_open : Icons.group_add),
                    label: Text(group.isPrivate ? 'Request to Join' : 'Join Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: CText(text: label, fontSize: 11, color: color),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CText(
            text: 'Welcome to the Community',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          SizedBox(height: 6.h),
          CText(
            text: 'Create private or public groups with age, location and condition filters.',
            fontSize: 13,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showCreateGroupSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CText(text: 'Create Community Group', fontSize: 18, fontWeight: FontWeight.bold),
              SizedBox(height: 12.h),
              TextField(
                controller: controller.groupNameController,
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: controller.groupDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => TextField(
                  onChanged: (v) => controller.groupLocationCode.value =
                      v.trim().isEmpty ? 'GLOBAL' : v.trim().toUpperCase(),
                  decoration: InputDecoration(
                    labelText: 'Location code (e.g. US, UAE, GLOBAL)',
                    hintText: controller.groupLocationCode.value,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private group'),
                  value: controller.createGroupPrivate.value,
                  onChanged: (v) => controller.createGroupPrivate.value = v,
                ),
              ),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Manual approval required'),
                  value: controller.createGroupNeedsApproval.value,
                  onChanged: (v) => controller.createGroupNeedsApproval.value = v,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.groupConditionController,
                      decoration: const InputDecoration(labelText: 'Allowed diagnosis'),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.addDraftCondition,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.groupInstructionController,
                      decoration: const InputDecoration(labelText: 'Add instruction'),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.addDraftInstruction,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.createGroup();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _categoryTile({
    required String title,
    required String subtitle,
    required String postsCount,
    required String iconEmoji,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48.h,
              width: 48.h,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(iconEmoji, style: TextStyle(fontSize: 24.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(
                    text: title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CText(
                    text: subtitle,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.post_add, size: 14.sp, color: AppColors.primary),
                      SizedBox(width: 4.w),
                      CText(text: postsCount, fontSize: 11, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
