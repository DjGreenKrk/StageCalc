import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:stagecalc/infrastructure/remote/pocketbase_auth_service.dart';

/// `AuthStore.isValid` decodes the middle segment of a real JWT looking for
/// a future `exp` claim (see `package:pocketbase`'s `auth_store.dart`) - the
/// header/signature segments are never inspected, so any non-empty
/// placeholder works for those.
String _fakeJwt({int expiresInSeconds = 3600}) {
  final exp =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresInSeconds;
  final payload = base64
      .encode(utf8.encode('{"exp":$exp}'))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

void main() {
  late PocketBase pb;
  late PocketBaseAuthService service;

  setUp(() {
    pb = PocketBase('http://example.invalid');
    service = PocketBaseAuthService(pb);
  });

  test('reports logged out when nothing has been saved into the store', () {
    expect(service.isLoggedIn, isFalse);
    expect(service.currentUserEmail, isNull);
    expect(service.currentUserId, isNull);
  });

  test('reflects a session already present in the auth store', () {
    // Simulates what `authWithPassword` does internally, without a network
    // call - `PocketBaseAuthService` must read this same store, not keep
    // its own separate copy of "who is logged in".
    pb.authStore.save(
      _fakeJwt(),
      RecordModel({'id': 'user1', 'email': 'crew@example.com'}),
    );

    expect(service.isLoggedIn, isTrue);
    expect(service.currentUserEmail, 'crew@example.com');
    expect(service.currentUserId, 'user1');
  });

  test('treats an expired token as logged out', () {
    pb.authStore.save(
      _fakeJwt(expiresInSeconds: -3600),
      RecordModel({'id': 'user1', 'email': 'crew@example.com'}),
    );

    expect(service.isLoggedIn, isFalse);
  });

  test('logout clears the store', () {
    pb.authStore.save(
      _fakeJwt(),
      RecordModel({'id': 'user1', 'email': 'crew@example.com'}),
    );

    service.logout();

    expect(service.isLoggedIn, isFalse);
    expect(pb.authStore.token, isEmpty);
  });
}
