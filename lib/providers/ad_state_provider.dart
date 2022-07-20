import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_state.dart';

final adStateProvider = Provider<AdState>((ref) {
  return AdState();
});
