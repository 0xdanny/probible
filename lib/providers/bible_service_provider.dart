import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bible_service.dart';

final bibleServiceProvider = Provider<BibleService>((ref) {
  return BibleService();
});
