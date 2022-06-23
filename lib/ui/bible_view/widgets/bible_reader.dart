import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chapter.dart';
import '../../../providers/reader_settings_repository_provider.dart';

class BibleReader extends ConsumerWidget {
  const BibleReader({Key? key, required this.chapter}) : super(key: key);

  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [const SizedBox(height: 10)];

    for (int i = 0; i < chapter.verses!.length; i++) {
      var item = chapter.verses![i];
      children.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: item.verseId.toString(),
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: ref
                              .watch(readerSettingsRepositoryProvider)
                              .verseNumberSize *
                          1.1,
                      fontFamily:
                          ref.watch(readerSettingsRepositoryProvider).typeFace,
                    ),
              ),
              const TextSpan(text: "  "),
              TextSpan(
                text: item.text,
                style: Theme.of(context).textTheme.headline5!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: ref
                              .watch(readerSettingsRepositoryProvider.notifier)
                              .bodyTextSize *
                          1.4,
                      height: ref
                              .watch(readerSettingsRepositoryProvider.notifier)
                              .bodyTextHeight *
                          1.1,
                      fontFamily:
                          ref.watch(readerSettingsRepositoryProvider).typeFace,
                    ),
              ),
            ]),
          ),
        ),
      );

      if (!(i == chapter.verses!.length - 1)) {
        children.add(const SizedBox(height: 12));
      }
    }

    children.add(const SizedBox(height: 40));

    return SingleChildScrollView(
      child: Column(
        children: [...children],
      ),
    );
  }
}
