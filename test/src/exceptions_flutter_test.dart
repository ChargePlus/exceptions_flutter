// ignore_for_file: prefer_const_constructors
import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceException', () {
    test('can be instantiated with all parameters', () {
      final exception = ServiceException(
        code: 'error_code',
        message: 'An error occurred.',
        displayMessageKey: 'error_message_key',
        stackTrace: StackTrace.current,
      );

      expect(exception.code, 'error_code');
      expect(exception.message, 'An error occurred.');
      expect(exception.displayMessageKey, 'error_message_key');
      expect(exception.stackTrace, isNotNull);
    });

    test('supports value equality', () {
      expect(
        ServiceException(
          code: 'code1',
          message: 'message1',
          displayMessageKey: 'key1',
          stackTrace: StackTrace.empty,
        ),
        equals(
          ServiceException(
            code: 'code1',
            message: 'message1',
            displayMessageKey: 'key1',
            stackTrace: StackTrace.empty,
          ),
        ),
      );
    });

    test('props are correct', () {
      final exception = ServiceException(
        code: 'code1',
        message: 'message1',
        displayMessageKey: 'key1',
        stackTrace: StackTrace.empty,
      );

      expect(
        exception.props,
        ['code1', 'message1', 'key1', StackTrace.empty],
      );
    });

    test('instances with different properties are not equal', () {
      final exception1 = ServiceException(
        code: 'code1',
        message: 'message1',
        displayMessageKey: 'key1',
        stackTrace: StackTrace.empty,
      );

      final exception2 = ServiceException(
        code: 'code2',
        message: 'message2',
        displayMessageKey: 'key2',
        stackTrace: StackTrace.empty,
      );

      expect(exception1, isNot(exception2));
    });

    test('can be instantiated with no arguments', () {
      expect(
        const ServiceException(),
        const ServiceException(),
      );
    });

    test('implements Exception', () {
      final exception = ServiceException();
      expect(exception, isA<Exception>());
    });
  });
}
