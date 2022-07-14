import 'package:equatable/equatable.dart';

/// {@template exceptions_repository}
/// Repository which provides exceptions in a format to users
/// {@endtemplate}
class ServiceException extends Equatable implements Exception {
  /// {@macro exceptions_repository}
  const ServiceException({
    this.code,
    this.message,
    this.stackTrace,
  });

  /// The optional code to accommodate the message.
  ///
  /// Allows users to identify the exception from a short code-name, for example
  /// "wrong-password" is used when a user insert the wrong password
  final String? code;

  /// The long form message of the exception.
  final String? message;

  /// An interface implemented by all stack trace objects.
  /// A [StackTrace] is intended to convey information to the user about the
  /// call sequence that triggered an exception.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [code, message, stackTrace];
}
