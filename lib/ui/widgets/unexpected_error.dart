import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnexpectedError extends ConsumerWidget {
  const UnexpectedError(this.provider, {Key? key}) : super(key: key);

  final AutoDisposeFutureProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Oops, something unexpected happened :(',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline5,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27.5),
                ),
                padding: EdgeInsets.zero,
                fixedSize:
                    Size(MediaQuery.of(context).size.width / 2 - 90, 45)),
            onPressed: () => ref.refresh(provider),
            child: Text(
              "Retry",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
