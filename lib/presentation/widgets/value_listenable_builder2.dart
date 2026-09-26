import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Helper for listening to two [ValueListenable]s at once.
///
/// This used to be copy-pasted into both `add_category.dart` and
/// `add_source_screen.dart` as an identical top-level class. Keeping
/// two independent definitions of the same name floating around is a
/// latent "ambiguous_import" compile error waiting to happen the
/// moment a third file imports both of those screens and tries to use
/// this widget - so it now lives in exactly one place.
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: first,
    builder: (context, a, _) => ValueListenableBuilder<B>(
      valueListenable: second,
      builder: (context, b, _) => builder(context, a, b, null),
    ),
  );
}
