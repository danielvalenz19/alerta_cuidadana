import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/http_client.dart';

class IncidentRepository {
  final Dio _dio = HttpClient.dio;
  final _battery = Battery();
  final _deviceInfo = DeviceInfoPlugin();
  final _ss = const FlutterSecureStorage();

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Ubicación deshabilitada');
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, dynamic>> _device() async {
    if (Platform.isAndroid) {
      final a = await _deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'version': a.version.release ?? 'unknown',
        'model': a.model
      };
    } else if (Platform.isIOS) {
      final i = await _deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'version': i.systemVersion ?? 'unknown',
        'model': i.utsname.machine
      };
    }
    return {'platform': 'unknown', 'version': '', 'model': ''};
  }

  Future<int> createIncident() async {
    final pos = await _getPosition();
    final bat = await _battery.batteryLevel;
    final dev = await _device();
    final payload = {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy.toInt(),
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'source': 'mobile',
      'battery': bat,
      'device': dev,
    };
    final access = await _ss.read(key: 'access_token');
    if (access == null || access.isEmpty) {
      throw Exception('No hay access_token almacenado. Inicia sesión de nuevo.');
    }

    final r = await _dio.post(
      '/incidents',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
    return (r.data['id'] as num).toInt();
  }

  Future<void> cancelIncident(int id, String pin) async {
    final access = await _ss.read(key: 'access_token');
    await _dio.post(
      '/incidents/$id/cancel',
      data: {'pin': pin},
      options: access != null && access.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $access'})
          : null,
    );
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final r = await _dio.get('/incidents/$id');
    return r.data as Map<String, dynamic>;
  }
}
