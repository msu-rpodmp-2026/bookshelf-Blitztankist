import 'dart:async';

void main() {
  print('A');
  Future(() => print('B'));
  Future.delayed(Duration.zero, () => print('C'));
  Future.value(0).then((_) => print('D'));
  scheduleMicrotask(() => print('E'));
  print('F');
}
