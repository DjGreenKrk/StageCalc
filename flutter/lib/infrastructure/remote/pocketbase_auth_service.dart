import 'package:pocketbase/pocketbase.dart';

/// Thin wrapper around the `users` PocketBase auth collection (ADR-028).
/// The actual session lives in [PocketBase.authStore] (persisted via
/// `PocketBaseClientProvider`) - this class just names the two operations
/// the UI needs and reads that same store, so there is exactly one source
/// of truth for "who is logged in" instead of a second copy of it here.
class PocketBaseAuthService {
  const PocketBaseAuthService(this._pb);

  final PocketBase _pb;

  bool get isLoggedIn => _pb.authStore.isValid;

  String? get currentUserEmail => _pb.authStore.record?.getStringValue('email');

  String? get currentUserId => _pb.authStore.record?.id;

  Future<void> login(String email, String password) {
    return _pb.collection('users').authWithPassword(email, password);
  }

  void logout() {
    _pb.authStore.clear();
  }
}
