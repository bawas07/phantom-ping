import 'package:get/get.dart';

import '../controllers/broadcast_composer_controller.dart';

class BroadcastComposerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BroadcastComposerController>(
      () => BroadcastComposerController(),
    );
  }
}
