import 'package:get/get.dart';

import '../../data/models/organization.dart';
import '../../data/repositories/organization_repository.dart';
import '../../services/auth_service.dart';

class OrganizationDashboardController extends GetxController {
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<Organization?> organization = Rx<Organization?>(null);
  final RxInt userCount = 0.obs;
  final RxInt topicCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      // Fetch organization details
      final org = await _orgRepository.getOrganization(user.organizationId);
      organization.value = org;

      // Fetch organization stats
      final stats = await _orgRepository.getOrganizationStats(
        user.organizationId,
      );
      userCount.value = stats['userCount'] as int? ?? 0;
      topicCount.value = stats['topicCount'] as int? ?? 0;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isOwner => _authService.currentUser.value?.isOwner ?? false;

  void navigateToUserManagement() {
    Get.toNamed('/user-management');
  }

  void navigateToTopicManagement() {
    Get.toNamed('/topic-management');
  }

  void navigateToBroadcast() {
    Get.toNamed('/broadcast-composer');
  }

  void navigateToOwnershipTransfer() {
    Get.toNamed('/ownership-transfer');
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed('/login');
  }
}
