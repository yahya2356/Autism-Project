import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/network_checker_service.dart';
import '../services/role_auth_service.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/safe_zone_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/places_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/reviews_repository.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/category_repository.dart';
class InitialBinding extends Bindings {
  @override
  void dependencies() {

    // =============== Services (Base)
    Get.put(AuthService(), permanent: true);
    Get.put(FirestoreService(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(NetworkCheckerService(), permanent: true);

    //  === Repositories -----------
    Get.put(AuthRepository(Get.find<AuthService>()), permanent: true);
    Get.put(UserRepository(Get.find<FirestoreService>()), permanent: true);
    Get.put(SafeZoneRepository(Get.find<FirestoreService>()), permanent: true);
    Get.put(CommunityRepository(), permanent: true);
    Get.put(PlacesRepository(), permanent: true);
    Get.put(ChildRepository(), permanent: true);
    Get.put(CategoryRepository(), permanent: true);
    Get.put(FavoritesRepository(Get.find<FirestoreService>().firestore), permanent: true);
    Get.put(ReviewsRepository(Get.find<FirestoreService>().firestore), permanent: true);

    // =============== Services (Dependent)
    Get.put(AiChatService(), permanent: true);
    Get.put(AiService(), permanent: true);
    Get.put(RoleAuthService(), permanent: true);
    Get.putAsync(() => NotificationService().init(), permanent: true);
  }
}
