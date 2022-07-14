// ignore_for_file: prefer_const_constructors
import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExceptionsFlutter', () {
    test('can be instantiated', () {
      expect(ServiceException(), isNotNull);
    });
  });
}
