import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorBody extends ConsumerWidget {
  final String message;
  final AutoDisposeFutureProvider provider;

  const ErrorBody(this.message, this.provider, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27.5),
              ),
              padding: EdgeInsets.zero,
              fixedSize: Size(MediaQuery.of(context).size.width / 2 - 90, 45)),
          onPressed: () => ref.refresh(provider),
          child: Text(
            "Retry",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}
