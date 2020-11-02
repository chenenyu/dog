# Dog

Dart log package, simple and pretty.

## Getting Started

### Install

```yaml
dependencies:
  dog: any
```

```dart
import 'package:dog/dog.dart';

Dog dog = Dog();
```

### Usage

```dart
// simple log
dog.v('verbose');
dog.d('debug');
dog.i('info');
dog.w('warning');
dog.e('error');
```
![](art/1.png)

```dart
// Map.
dog.i({
  'a': 1,
  'b': {'b1': '2', 'b2': '2'},
  'c': 3
});
// Iterable.
dog.w([1, 2, 3, 4, 5]);
// Function.
dog(() => 'This this a message returned by a Function.');
```
![](art/2.png)

```dart
// Exception/StackTrace
try {
  throw Exception('This is an exception.');
} catch (e, st) {
  dog.e(e, stackTrace: st);
}
```
![](art/3.png)

