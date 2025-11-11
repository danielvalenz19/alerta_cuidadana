import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../core/http_client.dart';

class IncidentService {
  IncidentService({
    Dio? dio,
    Battery? battery,
    DeviceInfoPlugin? deviceInfo,
  })  : _dio = dio ?? HttpClient.dio,
        _battery = battery ?? Battery(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final Dio _dio;
  final Battery _battery;
  final DeviceInfoPlugin _deviceInfo;

  Future<String> createIncident() async {
    final position = await _getPosition();
    final batteryLevel = (await _battery.batteryLevel).clamp(0, 100);
    final device = await _deviceMetadata();

    final accuracy = position.accuracy.isFinite ? position.accuracy.round() : null;
    final payload = <String, dynamic>{
      'lat': double.parse(position.latitude.toStringAsFixed(6)),
      'lng': double.parse(position.longitude.toStringAsFixed(6)),
      'battery': batteryLevel,
      'device': device,
      if (accuracy != null) 'accuracy': accuracy,
    };

    final response = await _dio.post('incidents', data: payload);
    final data = response.data;
    final id = data['id'] ?? (data['data'] is Map<String, dynamic> ? data['data']['id'] : null);

    if (id == null) {
      throw Exception('El backend no retorno el id del incidente');
    }
    return '$id';
  }

  Future<void> cancelIncident(String incidentId, {String? reason}) async {
    final data = (reason != null && reason.isNotEmpty) ? {'reason': reason} : null;
    await _dio.post('incidents/$incidentId/cancel', data: data);
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Activa la ubicacion para enviar la alerta');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicacion denegado');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<Map<String, String>> _deviceMetadata() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final release = info.version.release.trim();
      return {
        'os': 'android',
        'version': release.isEmpty ? 'unknown' : release,
      };
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      final systemVersion = info.systemVersion.trim();
      return {
        'os': 'ios',
        'version': systemVersion.isEmpty ? 'unknown' : systemVersion,
      };
    }
    return const {'os': 'unknown', 'version': 'unknown'};
  }
}
