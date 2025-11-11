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
      throw Exception('Ubicacion deshabilitada');
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicacion denegado');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<(String os, String ver)> _os() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return ('android', info.version.release ?? 'unknown');
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return ('ios', info.systemVersion ?? 'unknown');
    }
    return ('unknown', '');
  }

  Future<int> createIncident() async {
    final pos = await _getPosition();
    final bat = await _battery.batteryLevel;
    final (os, ver) = await _os();
    final payload = {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy.toInt(),
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'source': 'mobile',
      'init_battery': bat,
      'device_os': os,
      'device_ver': ver,
    };
    final access = await _ss.read(key: 'access_token');
    if (access == null || access.isEmpty) {
      throw Exception('No hay access_token almacenado. Inicia sesion de nuevo.');
    }

    final response = await _dio.post(
      'incidents',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
    return (response.data['id'] as num).toInt();
  }

  Future<void> cancelIncident(int id, String pin) async {
    final access = await _ss.read(key: 'access_token');
    await _dio.post(
      'incidents/$id/cancel',
      data: {'pin': pin},
      options: access != null && access.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $access'})
          : null,
    );
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final response = await _dio.get('incidents/$id');
    return response.data as Map<String, dynamic>;
  }
}
