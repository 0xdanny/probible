import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../config/exceptions.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/translation.dart';
import '../../providers/bible_books_provider.dart';
import '../../providers/bible_chapters_provider.dart';
import '../../providers/bible_repository_provider.dart';
import '../../providers/bible_translations_provider.dart';
import '../../providers/last_translation_book_chapter_provider.dart';
import '../../providers/reader_settings_repository_provider.dart';
import '../../services/bible_service.dart';
import '../widgets/error_body.dart';
import '../widgets/unexpected_error.dart';
import 'widgets/bible_reader.dart';

class BibleView extends ConsumerStatefulWidget {
  const BibleView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BibleViewState();
}

class _BibleViewState extends ConsumerState<BibleView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBookAndChapterBottomSheet();
    });
    super.initState();
  }

  void _loadData() async {
    ref.read(localRepositoryProvider.notifier).loadLastChapterAndTranslation();
    ref.read(readerSettingsRepositoryProvider).loadData();
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(bibleTranslationsProvider);
    final booksRepo = ref.watch(bibleBooksProvider);
    final chaptersRepo = ref.watch(bibleChaptersProvider);

    translations.sort((a, b) => a.id!.compareTo(b.id!));

    return booksRepo.when(
      error: (e, _) {
        if (e is Exceptions) {
          return ErrorBody(e.message, bibleBooksProvider);
        }
        return UnexpectedError(bibleBooksProvider);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (books) {
        return chaptersRepo.when(
          error: (e, s) {
            if (e is Exceptions) {
              return ErrorBody(e.message, bibleChaptersProvider);
            }
            return UnexpectedError(bibleChaptersProvider);
          },
          loading: () => Container(),
          data: (chapter) {
            // _isBookmarked = _isBookmarked = ref
            //     .watch(studyToolsRepositoryProvider)
            //     .bookmarkedChapters
            //     .where((e) =>
            //         e.id == chapter.id &&
            //         e.verses![0].book.id == chapter.verses![0].book.id)
            //     .isNotEmpty;

            final kChapter = chapter.copyWith(verses: [
              for (var item in chapter.verses!)
                item.copyWith(text: item.text.replaceAll('\\"', '"')),
            ]);

            return _buildMobileContent(
                context, ref, translations, books, kChapter);
          },
        );
      },
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    WidgetRef ref,
    List<Translation> translations,
    List<Book> books,
    Chapter chapter,
  ) {
    Widget reader() {
      return SliverToBoxAdapter(
        child: BibleReader(chapter: chapter),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildMobileHeader(context, ref, translations, books, chapter),
              reader()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(
    BuildContext context,
    WidgetRef ref,
    List<Translation> translations,
    List<Book> books,
    Chapter chapter,
  ) {
    Widget _previousChapterButton() {
      return GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();

          await ref
              .read(bibleRepositoryProvider)
              .goToNextPreviousChapter(ref, true);
        },
        child: Icon(
          Icons.chevron_left,
          size: 27,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    Widget _nextChapterButton() {
      return GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();

          await ref
              .read(bibleRepositoryProvider)
              .goToNextPreviousChapter(ref, false);
        },
        child: Icon(
          Icons.chevron_right,
          size: 27,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    Widget _bookmarkButton(Chapter chapter) {
      return IconButton(
        onPressed: () async {
          HapticFeedback.lightImpact();

          // setState(() {
          //   _isBookmarked = !_isBookmarked;
          // });

          // if (_isBookmarked) {
          //   await ref
          //       .read(studyToolsRepositoryProvider.notifier)
          //       .addBookmarkChapter(chapter);
          // } else {
          //   await ref
          //       .read(studyToolsRepositoryProvider.notifier)
          //       .removeBookmarkChapter(chapter);
          // }
        },
        icon: Icon(
          Icons.bookmark,
          // _isBookmarked
          //     ? CupertinoIcons.bookmark_fill
          //     : CupertinoIcons.bookmark,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
          // _isBookmarked
          //     ? Theme.of(context).primaryColor
          //     : Theme.of(context).colorScheme.primary,
        ),
      );
    }

    Widget _readerSettingsButton() {
      return IconButton(
        onPressed: () async {
          HapticFeedback.lightImpact();

          await _showReaderSettingsBottomSheet();
        },
        icon: Icon(
          Icons.settings,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    Widget _translationControls(
        String bookChapterTitle, List<Translation> translations) {
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();

              await _showBookAndChapterBottomSheet();
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(10)),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              child: Text(
                bookChapterTitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();

              await _showTranslationsBottomSheet(context, translations);
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(10)),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              child: Text(
                translations[int.parse(translationID)]
                    .abbreviation!
                    .toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    Widget _chapterVerseTranslationControls(
        List<Translation> translations, List<Book> books, Chapter chapter) {
      var bookChapterTitle =
          '${chapter.verses![0].book.name!} ${chapter.number!}';

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _previousChapterButton(),
          const Spacer(),
          _readerSettingsButton(),
          const Spacer(),
          _translationControls(bookChapterTitle, translations),
          const Spacer(),
          _bookmarkButton(chapter),
          const Spacer(),
          _nextChapterButton(),
        ],
      );
    }

    return SliverAppBar(
      centerTitle: true,
      floating: true,
      // backgroundColor: ,
      title: _chapterVerseTranslationControls(translations, books, chapter),
    );
  }

  Future<void> _showReaderSettingsBottomSheet() async {
    var screenBrightness = await ScreenBrightness().system;

    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              Widget brightnessControls = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.brightness_low, size: 27),
                    Expanded(
                      child: Slider(
                        value: screenBrightness,
                        onChanged: (val) async {
                          await ScreenBrightness().setScreenBrightness(val);
                          setState(() => screenBrightness = val);
                        },
                      ),
                    ),
                    const Icon(Icons.brightness_high, size: 34),
                  ],
                ),
              );

              Widget textSizeControls = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Text Size',
                        style: Theme.of(context).textTheme.headline5),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .decrementBodyTextSize();
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .decrementVerseNumberSize();
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'A',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              ?.copyWith(
                                fontSize: 16,
                                height: 1.25,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .incrementBodyTextSize();
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .incrementVerseNumberSize();
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'A',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              ?.copyWith(
                                fontSize: 24,
                                height: 1.25,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              Widget lineHeightControls = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Line Spacing',
                        style: Theme.of(context).textTheme.headline5),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .decrementBodyTextHeight();
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .decrementVerseNumberHeight();
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.format_line_spacing,
                            color: Theme.of(context).colorScheme.onBackground,
                            size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .incrementBodyTextHeight();
                        await ref
                            .read(readerSettingsRepositoryProvider)
                            .incrementVerseNumberHeight();
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.format_line_spacing,
                            color: Theme.of(context).colorScheme.onBackground,
                            size: 26),
                      ),
                    ),
                  ],
                ),
              );

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    brightnessControls,
                    const Divider(height: 34),
                    textSizeControls,
                    const SizedBox(height: 17),
                    const Divider(),
                    const SizedBox(height: 5),
                    lineHeightControls,
                    const Divider(height: 34),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showBookAndChapterBottomSheet() async {
    List<Book> books = await BibleService().getBooks('');

    Widget _bookCard(Book book) {
      Widget _chapterCard(ChapterId chapter) {
        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ref
                .read(bibleRepositoryProvider)
                .changeChapter(ref, book.id!, chapter.id!);
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.secondary, width: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                chapter.id.toString(),
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        );
      }

      return ExpansionTile(
        childrenPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(book.name!, style: Theme.of(context).textTheme.headline6),
        iconColor: Theme.of(context).colorScheme.primary,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.0,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              itemCount: book.chapters!.length,
              itemBuilder: (context, index) =>
                  _chapterCard(book.chapters![index]),
            ),
          ),
        ],
      );
    }

    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 27),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Books',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: ListView.separated(
                  itemCount: books.length,
                  separatorBuilder: (context, index) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(),
                    );
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        if (index == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  child: Text(
                                    'Old Testament',
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        _bookCard(books[index]),
                        if (index == 38)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Text(
                              'New Testament',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTranslationsBottomSheet(
      BuildContext context, List<Translation> translations) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 27),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Versions',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: ListView.separated(
                  itemCount: translations.length,
                  separatorBuilder: (context, index) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(),
                    );
                  },
                  itemBuilder: (context, index) {
                    var translation = translations[index];
                    Widget _translationCard() {
                      return GestureDetector(
                        onTap: () async {
                          await ref
                              .read(localRepositoryProvider.notifier)
                              .changeBibleTranslation(
                                index,
                                translation.abbreviation!.toLowerCase(),
                              );

                          ref.refresh(bibleChaptersProvider);
                          setState(() {});

                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 3, horizontal: 24),
                          title: Text(translation.name!,
                              style: Theme.of(context).textTheme.headline6),
                          trailing: Text(
                            translation.abbreviation!.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.bodyText1?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (index == 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Divider(),
                          ),
                        _translationCard(),
                        if (index == translations.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Divider(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
