import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/bible_repository.dart';

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository();
});
