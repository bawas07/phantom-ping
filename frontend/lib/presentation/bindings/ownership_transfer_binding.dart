import 'package:get/get.dart';

import '../controllers/ownership_transfer_controller.dart';

class OwnershipTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OwnershipTransferController>(
      () => OwnershipTransferController(),
    );
  }
}
