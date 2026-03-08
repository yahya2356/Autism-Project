import 'package:bluecircle/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/c_text.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/child_model.dart';
import 'children_management_controller.dart';

class ChildrenManagementView extends GetView<ChildrenManagementController> {
  const ChildrenManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: "My Children",
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              controller.clearForm();
              Get.toNamed(Routes.ADD_CHILD);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.children.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.children.length,
          itemBuilder: (context, index) {
            final child = controller.children[index];
            return _buildChildCard(child);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.clearForm();
          Get.toNamed(Routes.ADD_CHILD);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Child"),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 80.w,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              "No Children Added Yet",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Add your children to manage their profiles and track their progress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                controller.clearForm();
                Get.toNamed(Routes.ADD_CHILD);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Your First Child"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => controller.navigateToChildDashboard(child),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: child.profileImageUrl != null
                        ? NetworkImage(child.profileImageUrl!)
                        : null,
                    child: child.profileImageUrl == null
                        ? Icon(Icons.person, size: 32.r, color: AppColors.primary)
                        : null,
                  ),
                ),
                SizedBox(width: 16.w),
                
                // Child Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText(
                        text: child.childName,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(height: 4.h),
                      // Row(
                      //   children: [
                      //     Icon(Icons.cake_outlined, size: 14.sp, color: AppColors.primary),
                      //     SizedBox(width: 4.w),
                      //     CText(
                      //       text: "${child.age} Years Old",
                      //       fontSize: 14,
                      //       color: AppColors.textSecondary,
                      //     ),
                      //   ],
                      // ),
                      if (child.notes != null && child.notes!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        CText(
                          text: child.notes!,
                          fontSize: 12,
                          color: AppColors.grey500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
              
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        controller.setChildForEdit(child);
                        Get.toNamed(Routes.EDIT_CHILD, arguments: child);
                        break;
                      case 'delete':
                        controller.deleteChild(child);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20.sp, color: AppColors.primary),
                          SizedBox(width: 12.w),
                          const CText(text: "Edit Profile", fontSize: 14),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20.sp, color: Colors.red),
                          SizedBox(width: 12.w),
                          const CText(text: "Remove", fontSize: 14, color: Colors.red),
                        ],
                      ),
                    ),
                  ],
                )])))));

  }}