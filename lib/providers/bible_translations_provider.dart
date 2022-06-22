import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/translation.dart';
import 'bible_repository_provider.dart';

String translationID = '';

final bibleTranslationsProvider = Provider<List<Translation>>((ref) {
  final bibleService = ref.watch(bibleRepositoryProvider);
  final versions = bibleService.translations;

  return versions;
});
