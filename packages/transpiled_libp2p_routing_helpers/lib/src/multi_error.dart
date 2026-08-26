// lib/src/multi_error.dart
//
// Small stand-in for go.uber.org/multierr, used throughout
// go-libp2p-routing-helpers to combine errors from several sub-routers
// into one. Not a real Go module dependency worth its own package for
// two functions.

/// Aggregates zero or more underlying errors. Equivalent to
/// go.uber.org/multierr's combined-error value (the one `multierr.Append`/
/// `multierr.Combine` build when there's more than one error).
class MultiError implements Exception {
  /// Creates the exception wrapping [errors] (must be non-empty).
  MultiError(this.errors)
    : assert(errors.isNotEmpty, 'MultiError needs at least one error');

  /// The underlying errors, in the order they were added.
  final List<Object> errors;

  @override
  String toString() => errors.map((e) => e.toString()).join('; ');
}

/// Appends [next] onto [current] (either of which may be `null`),
/// returning a single error value: `null` if both are `null`, the
/// non-null one if only one is set, or a [MultiError] combining both.
/// Equivalent to go.uber.org/multierr's `Append`.
Object? appendError(Object? current, Object? next) {
  if (next == null) return current;
  if (current == null) return next;
  final errors = current is MultiError ? current.errors : [current];
  return MultiError([...errors, next]);
}

/// Combines [errors] into a single error value: `null` if empty, the sole
/// error if there's exactly one, or a [MultiError] otherwise. Equivalent
/// to go.uber.org/multierr's `Combine`.
Object? combineErrors(List<Object> errors) {
  if (errors.isEmpty) return null;
  if (errors.length == 1) return errors.single;
  return MultiError(errors);
}
