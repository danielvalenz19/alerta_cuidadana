import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinVault {
  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kFail = 'pin_fail_count';
  static const _kLock = 'pin_lock_until_ms';

  static const _maxFails = 5;
  static const _cooldownMs = 60 * 1000;

  const PinVault(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> setPin(String pin) async {
    _requireFormat(pin);
    final salt = _genSalt();
    final hash = _hash(pin, salt);
    await _writeSaltAndHash(salt, hash);
    await _resetLock();
  }

  Future<bool> verify(String pin) async {
    if (await _isLocked()) return false;
    final matches = await _compare(pin);
    if (matches) {
      await _resetLock();
      return true;
    }
    await _registerFail();
    return false;
  }

  Future<void> changePin({required String current, required String next}) async {
    _requireFormat(next);
    final valid = await verify(current);
    if (!valid) {
      throw Exception('PIN actual incorrecto o bloqueado');
    }
    final salt = _genSalt();
    final hash = _hash(next, salt);
    await _writeSaltAndHash(salt, hash);
  }

  Future<bool> exists() async {
    final salt = await _storage.read(key: _kSalt);
    final hash = await _storage.read(key: _kHash);
    return salt != null && hash != null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kHash);
    await _resetLock();
  }

  Future<bool> isLocked() async => (await lockoutRemaining()) != null;

  Future<Duration?> lockoutRemaining() async {
    final untilStr = await _storage.read(key: _kLock);
    if (untilStr == null) return null;
    final until = int.tryParse(untilStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= until) {
      await _resetLock();
      return null;
    }
    return Duration(milliseconds: until - now);
  }

  // ---- helpers ----

  void _requireFormat(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw Exception('PIN debe ser de 4 a 6 digitos');
    }
  }

  List<int> _genSalt([int length = 16]) {
    final rand = Random.secure();
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  List<int> _hash(String pin, List<int> salt) {
    final bytes = <int>[...salt, ...utf8.encode(pin)];
    return sha256.convert(bytes).bytes;
  }

  Future<void> _writeSaltAndHash(List<int> salt, List<int> hash) async {
    await _storage.write(key: _kSalt, value: base64Encode(salt));
    await _storage.write(key: _kHash, value: base64Encode(hash));
  }

  Future<bool> _compare(String pin) async {
    final saltB64 = await _storage.read(key: _kSalt);
    final hashB64 = await _storage.read(key: _kHash);
    if (saltB64 == null || hashB64 == null) return false;
    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final got = _hash(pin, salt);
    return _constantEquals(got, expected);
  }

  bool _constantEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<bool> _isLocked() async {
    final remaining = await lockoutRemaining();
    return remaining != null;
  }

  Future<void> _registerFail() async {
    final currentStr = await _storage.read(key: _kFail);
    final current = int.tryParse(currentStr ?? '0') ?? 0;
    final next = current + 1;
    await _storage.write(key: _kFail, value: '$next');
    if (next >= _maxFails) {
      final until = DateTime.now().millisecondsSinceEpoch + _cooldownMs;
      await _storage.write(key: _kLock, value: '$until');
      await _storage.write(key: _kFail, value: '0');
    }
  }

  Future<void> _resetLock() async {
    await _storage.delete(key: _kFail);
    await _storage.delete(key: _kLock);
  }
}
