import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/services/ai_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/group_join_request_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_post_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/user_repository.dart';

class CommunityController extends GetxController {
  final CommunityRepository _communityRepository = Get.find<CommunityRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final AiService _aiService = Get.find<AiService>();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();
  final TextEditingController groupConditionController = TextEditingController();
  final TextEditingController groupInstructionController = TextEditingController();
  final TextEditingController joinRequestNoteController = TextEditingController();

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> filteredPosts = <PostModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final RxList<GroupModel> visibleGroups = <GroupModel>[].obs;
  final RxList<GroupModel> myGroups = <GroupModel>[].obs;
  final RxList<GroupJoinRequestModel> myJoinRequests = <GroupJoinRequestModel>[].obs;
  final RxList<GroupJoinRequestModel> ownerPendingRequests = <GroupJoinRequestModel>[].obs;
  final RxList<String> managedGroupIds = <String>[].obs;
  final Rxn<GroupModel> selectedGroup = Rxn<GroupModel>();
  final RxList<GroupPostModel> selectedGroupPosts = <GroupPostModel>[].obs;
  final RxBool isInSelectedGroup = false.obs;
  final RxBool isSummarizing = false.obs;
  final TextEditingController groupPostController = TextEditingController();
  final TextEditingController groupCountryController = TextEditingController();
  final TextEditingController groupCityController = TextEditingController();
  final TextEditingController groupLanguageController = TextEditingController();
  final Rxn<UserModel> currentUserProfile = Rxn<UserModel>();

  final RxString groupLocationCode = 'GLOBAL'.obs;
  final RxString groupCategory = 'General'.obs;
  final RxInt? minChildAge = RxInt(0);
  final RxInt? maxChildAge = RxInt(18);
  final RxBool createGroupPrivate = false.obs;
  final RxBool createGroupNeedsApproval = true.obs;
  final RxBool isLoading = false.obs;
  final RxList<String> draftConditions = <String>[].obs;
  final RxList<String> draftInstructions = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    dev.log('CommunityController Initialized', name: 'COMMUNITY_DEBUG');
    groups.bindStream(_communityRepository.getGroups());
    allPosts.bindStream(_communityRepository.getPosts());
    categories.bindStream(_categoryRepository.getCategories());

    ever(allPosts, (_) => _filterPosts());
    ever(selectedCategory, (_) => _filterPosts());
    everAll([groups, managedGroupIds], (_) => _filterGroups());

    searchController.addListener(_onSearchChanged);
    _initCurrentUserContext();
  }

  Future<void> _initCurrentUserContext() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    await _communityRepository.seedPublicGroupsIfEmpty(userId);
    currentUserProfile.value = await _userRepository.getUser(userId);
    myJoinRequests.bindStream(_communityRepository.getUserJoinRequests(userId));
    ownerPendingRequests.bindStream(_communityRepository.getPendingJoinRequestsForOwner(userId));
    _communityRepository.getUserGroupIds(userId).listen((ids) {
      managedGroupIds.assignAll(ids);
      _filterGroups();
    });
  }

  void _onSearchChanged() {
    _filterPosts();
    _filterGroups();
  }

  void _filterPosts() {
    final query = searchController.text.toLowerCase();
    List<PostModel> posts = allPosts.toList();

    if (selectedCategory.value != null) {
      posts = posts.where((post) => post.categoryId == selectedCategory.value!.id).toList();
    }

    if (query.isNotEmpty) {
      posts = posts.where((post) {
        return post.title.toLowerCase().contains(query) ||
            post.description.toLowerCase().contains(query);
      }).toList();
    }

    filteredPosts.value = posts;
  }

  void _filterGroups() {
    final query = searchController.text.toLowerCase();
    final source = groups.toList();

    final filtered = source.where((group) {
      if (query.isEmpty) return true;
      return group.groupName.toLowerCase().contains(query) ||
          group.description.toLowerCase().contains(query) ||
          group.locationCode.toLowerCase().contains(query) ||
          group.allowedConditions.any((c) => c.toLowerCase().contains(query));
    }).toList();

    visibleGroups.assignAll(filtered);
    myGroups.assignAll(filtered.where((g) => managedGroupIds.contains(g.groupId)));
  }

  bool _passesLocation(GroupModel group, UserModel user) {
    final userLocation = (user.locationCode ?? 'GLOBAL').toUpperCase();
    if (group.allowedCountry?.trim().isNotEmpty == true) {
      final country = group.allowedCountry!.trim().toUpperCase();
      if (country != 'GLOBAL' && userLocation != country) return false;
    }
    if (group.allowedCity?.trim().isNotEmpty == true) {
      final city = group.allowedCity!.trim().toUpperCase();
      if (city != 'GLOBAL' && userLocation != city) return false;
    }

    if (group.locationCode.toUpperCase() == 'GLOBAL') return true;
    return userLocation == group.locationCode.toUpperCase();
  }

  bool _passesAge(GroupModel group, UserModel user) {
    if (user.childDob == null) return true;
    final now = DateTime.now();
    final age = now.year - user.childDob!.year -
        ((now.month < user.childDob!.month ||
                (now.month == user.childDob!.month && now.day < user.childDob!.day))
            ? 1
            : 0);

    if (group.minChildAge != null && age < group.minChildAge!) return false;
    if (group.maxChildAge != null && age > group.maxChildAge!) return false;
    return true;
  }

  bool _passesCondition(GroupModel group, UserModel user) {
    if (group.allowedConditions.isEmpty) return true;
    final diagnosis = (user.diagnosis ?? '').trim().toLowerCase();
    if (diagnosis.isEmpty) return false;
    return group.allowedConditions.map((e) => e.toLowerCase()).contains(diagnosis);
  }

  String? getEligibilityIssue(GroupModel group) {
    final user = currentUserProfile.value;
    if (user == null) return 'Please complete your profile first.';
    if (!_passesLocation(group, user)) {
      final locationLabel = group.allowedCity?.isNotEmpty == true
          ? '${group.allowedCity}, ${group.allowedCountry ?? group.locationCode}'
          : (group.allowedCountry ?? group.locationCode);
      return 'This group is restricted to $locationLabel families.';
    }
    if (!_passesAge(group, user)) {
      return 'Your child age does not match this group criteria.';
    }
    if (!_passesCondition(group, user)) {
      return 'Your child diagnosis does not match this group criteria.';
    }
    if ((group.allowedLanguage ?? '').trim().isNotEmpty) {
      final userLanguage = (user.preferredLanguage ?? user.preferredTextSize ?? '')
          .trim()
          .toLowerCase();
      final allowedLanguage = group.allowedLanguage!.trim().toLowerCase();
      if (userLanguage.isNotEmpty && userLanguage != allowedLanguage) {
        return 'This group requires language preference: ${group.allowedLanguage}.';
      }
    }
    return null;
  }


  bool canAccessGroup(GroupModel group) {
    if (!group.isPrivate) return true;
    return managedGroupIds.contains(group.groupId) || isGroupOwner(group);
  }

  void selectCategory(CategoryModel? category) {
    selectedCategory.value = category;
  }

  void clearCategoryFilter() {
    selectedCategory.value = null;
  }

  int getPostCountForCategory(String categoryId) {
    return allPosts.where((post) => post.categoryId == categoryId).length;
  }

  Future<void> likePost(String postId) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    try {
      await _communityRepository.likePost(postId, userId);
    } catch (e) {
      dev.log('Error liking post: $e', name: 'COMMUNITY_DEBUG');
      ErrorHandler.showErrorSnackBar(e);
    }
  }

  Future<void> submitJoinAction(GroupModel group) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    final isEligible = await _communityRepository.canJoinGroup(
      group,
      currentUserProfile.value,
    );
    if (!isEligible) {
      ErrorHandler.showErrorSnackBar('You do not meet the requirements for this group.');
      return;
    }

    final isMember = await _communityRepository.isUserMember(group.groupId, userId);
    if (isMember) {
      ErrorHandler.showSuccessSnackBar('Already joined', 'You are already a member of this group.');
      return;
    }

    try {
      final mustRequest = group.isPrivate || group.requiresApproval;
      if (mustRequest) {
        await _communityRepository.requestJoinGroup(
          groupId: group.groupId,
          userId: userId,
          note: joinRequestNoteController.text.trim(),
        );
        ErrorHandler.showSuccessSnackBar(
          'Request sent',
          'The group owner will review your request shortly.',
        );
      } else {
        await _communityRepository.joinGroup(group.groupId, userId);
        ErrorHandler.showSuccessSnackBar('Joined', 'You are now a member of ${group.groupName}.');
      }
      if (selectedGroup.value?.groupId == group.groupId && !mustRequest) {
        isInSelectedGroup.value = true;
      }
      joinRequestNoteController.clear();
    } catch (e) {
      dev.log('Error joining group: $e', name: 'COMMUNITY_DEBUG');
      ErrorHandler.showErrorSnackBar(e);
    }
  }

  Future<void> reviewJoinRequest({
    required GroupJoinRequestModel request,
    required String status,
  }) async {
    final reviewerId = _authRepository.currentUser?.uid;
    if (reviewerId == null) return;
    try {
      await _communityRepository.reviewJoinRequest(
        requestId: request.id,
        reviewerId: reviewerId,
        status: status,
      );
      ErrorHandler.showSuccessSnackBar(
        status == 'approved' ? 'Request approved' : 'Request rejected',
        status == 'approved'
            ? 'The member has been added to the group.'
            : 'The join request has been rejected.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(e);
    }
  }

  Future<bool> createGroup() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return false;

    final name = groupNameController.text.trim();
    final description = groupDescriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ErrorHandler.showErrorSnackBar('Please add group name and description.');
      return false;
    }

    if ((minChildAge?.value ?? 0) > (maxChildAge?.value ?? 18)) {
      ErrorHandler.showErrorSnackBar('Minimum age cannot be greater than maximum age.');
      return false;
    }

    isLoading.value = true;
    try {
      await _communityRepository.createGroup(
        GroupModel(
          groupId: '',
          groupName: name,
          description: description,
          category: groupCategory.value,
          createdAt: DateTime.now(),
          ownerId: userId,
          isPrivate: createGroupPrivate.value,
          requiresApproval: createGroupNeedsApproval.value,
          locationCode: groupLocationCode.value.toUpperCase(),
          allowedCountry: groupCountryController.text.trim().isEmpty
              ? null
              : groupCountryController.text.trim().toUpperCase(),
          allowedCity: groupCityController.text.trim().isEmpty
              ? null
              : groupCityController.text.trim().toUpperCase(),
          allowedLanguage: groupLanguageController.text.trim().isEmpty
              ? null
              : groupLanguageController.text.trim(),
          minChildAge: minChildAge?.value,
          maxChildAge: maxChildAge?.value,
          allowedConditions: draftConditions.toList(),
          instructions: draftInstructions.toList(),
          joinInstructions: draftInstructions.toList(),
        ),
      );

      groupNameController.clear();
      groupDescriptionController.clear();
      groupConditionController.clear();
      groupInstructionController.clear();
      groupCountryController.clear();
      groupCityController.clear();
      groupLanguageController.clear();
      draftConditions.clear();
      draftInstructions.clear();
      createGroupPrivate.value = false;
      createGroupNeedsApproval.value = true;
      groupLocationCode.value = 'GLOBAL';
      minChildAge?.value = 0;
      maxChildAge?.value = 18;
      ErrorHandler.showSuccessSnackBar('Group created', 'Your community group is live.');
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackBar(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void addDraftCondition() {
    final value = groupConditionController.text.trim();
    if (value.isEmpty) return;
    draftConditions.add(value);
    groupConditionController.clear();
  }

  void addDraftInstruction() {
    final value = groupInstructionController.text.trim();
    if (value.isEmpty) return;
    draftInstructions.add(value);
    groupInstructionController.clear();
  }


  Future<void> openGroup(GroupModel group) async {
    selectedGroup.value = group;
    selectedGroupPosts.clear();
    selectedGroupPosts.bindStream(_communityRepository.getGroupPosts(group.groupId));

    final userId = _authRepository.currentUser?.uid;
    if (userId != null) {
      isInSelectedGroup.value = await _communityRepository.isUserMember(group.groupId, userId);
    }
  }

  Future<bool> createSelectedGroupPost() async {
    final group = selectedGroup.value;
    final userId = _authRepository.currentUser?.uid;
    if (group == null || userId == null) return false;

    if (!isInSelectedGroup.value) {
      ErrorHandler.showErrorSnackBar('Join this group first to create posts.');
      return false;
    }

    final content = groupPostController.text.trim();
    if (content.isEmpty) {
      ErrorHandler.showErrorSnackBar('Write something before posting.');
      return false;
    }

    try {
      await _communityRepository.createGroupPost(
        group.groupId,
        GroupPostModel(
          postId: '',
          groupId: group.groupId,
          userId: userId,
          content: content,
          timestamp: DateTime.now(),
        ),
      );
      await openGroup(group);
      groupPostController.clear();
      ErrorHandler.showSuccessSnackBar('Posted', 'Your message was published to the group.');
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackBar(e);
      return false;
    }
  }

  Future<void> summarizeGroup() async {
    final group = selectedGroup.value;
    if (group == null) return;
    if (!isInSelectedGroup.value) {
      ErrorHandler.showErrorSnackBar('Join this group to summarize discussions.');
      return;
    }

    try {
      isSummarizing.value = true;
      final posts = await _communityRepository.getRecentGroupPosts(group.groupId);
      if (posts.isEmpty) {
        ErrorHandler.showErrorSnackBar('There are no posts to summarize yet.');
        return;
      }

      final combinedText = posts
          .map((p) => p.content.trim())
          .where((content) => content.isNotEmpty)
          .join('\n');

      if (combinedText.isEmpty) {
        ErrorHandler.showErrorSnackBar('There is no readable content to summarize.');
        return;
      }

      final truncatedInput =
          combinedText.length > 12000 ? combinedText.substring(0, 12000) : combinedText;
      final summary = await _aiService.summarizeGroupPosts(truncatedInput);
      if (summary.trim().isEmpty) {
        ErrorHandler.showErrorSnackBar('Summary came back empty. Please try again.');
        return;
      }

      Get.dialog(
        AlertDialog(
          title: const Text('Group Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(e);
    } finally {
      isSummarizing.value = false;
    }
  }

  bool isMemberOfGroup(String groupId) => managedGroupIds.contains(groupId);

  GroupJoinRequestModel? joinRequestForGroup(String groupId) {
    final matches = myJoinRequests.where((request) => request.groupId == groupId);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  bool isGroupOwner(GroupModel group) {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return false;
    return group.ownerId == userId;
  }

  List<GroupJoinRequestModel> pendingRequestsForGroup(String groupId) {
    return ownerPendingRequests.where((request) => request.groupId == groupId).toList();
  }

  Future<void> refreshPosts() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }


  GroupModel? findGroupById(String groupId) {
    try {
      return groups.firstWhere((g) => g.groupId == groupId);
    } catch (_) {
      return null;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String statusLabel(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  void removeDraftCondition(String value) {
    draftConditions.remove(value);
  }

  void removeDraftInstruction(String value) {
    draftInstructions.remove(value);
  }

  @override
  void onClose() {
    dev.log('CommunityController Closed', name: 'COMMUNITY_DEBUG');
    searchController.dispose();
    groupNameController.dispose();
    groupDescriptionController.dispose();
    groupConditionController.dispose();
    groupInstructionController.dispose();
    groupCountryController.dispose();
    groupCityController.dispose();
    groupLanguageController.dispose();
    joinRequestNoteController.dispose();
    groupPostController.dispose();
    super.onClose();
  }
}
