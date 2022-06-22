import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/translation_book_chapter.dart';
import '../repositories/last_translation_book_chapter_repository.dart';

final localRepositoryProvider = StateNotifierProvider<
    LastTranslationBookChapterRepository, TranslationBookChapter>((ref) {
  return LastTranslationBookChapterRepository();
});
