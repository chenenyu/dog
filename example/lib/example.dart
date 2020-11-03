import 'package:dog/dog.dart';

void main(List<String> args) {
  Dog dog = Dog();
  dog.v('verbose');
  dog.d('debug');
  dog.i('info');
  dog.w('warning');
  dog.e('error');
  dog.i({
    'a': 1,
    'b': {'b1': '2', 'b2': '2'},
    'c': 3
  });
  dog.w([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
      tag: 'MyTag');

  try {
    throw Exception('This is an exception.');
  } catch (e, st) {
    dog.e(e, stackTrace: st);
  }

  dog(() => 'This this a message returned by a Function.');
}