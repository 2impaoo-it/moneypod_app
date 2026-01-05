import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/utils/dio_client.dart';
import 'package:flutter/material.dart';

void main() {
  group('DioClient', () {
    setUp(() {
      // Reset before each test
      DioClient.reset();
    });

    group('getDio', () {
      test('returns a Dio instance', () {
        final dio = DioClient.getDio(null);
        expect(dio, isNotNull);
        expect(dio, isA<Dio>());
      });

      test('configures correct timeout settings', () {
        final dio = DioClient.getDio(null);
        expect(dio.options.connectTimeout, equals(const Duration(seconds: 30)));
        expect(dio.options.receiveTimeout, equals(const Duration(seconds: 30)));
      });

      test('configures Content-Type header', () {
        final dio = DioClient.getDio(null);
        expect(dio.options.headers['Content-Type'], equals('application/json'));
      });

      test('configures Accept header', () {
        final dio = DioClient.getDio(null);
        expect(dio.options.headers['Accept'], equals('application/json'));
      });

      test('configures ngrok skip header', () {
        final dio = DioClient.getDio(null);
        expect(
          dio.options.headers['ngrok-skip-browser-warning'],
          equals('true'),
        );
      });

      test('has interceptors', () {
        final dio = DioClient.getDio(null);
        expect(dio.interceptors, isNotEmpty);
      });
    });

    group('reset', () {
      test('reset does not throw', () {
        expect(() => DioClient.reset(), returnsNormally);
      });

      test('getDio works after reset', () {
        DioClient.reset();
        expect(() => DioClient.getDio(null), returnsNormally);
      });
    });

    group('setNavigatorKey', () {
      test('accepts GlobalKey', () {
        final key = GlobalKey<NavigatorState>();
        expect(() => DioClient.setNavigatorKey(key), returnsNormally);
      });
    });
  });
}
