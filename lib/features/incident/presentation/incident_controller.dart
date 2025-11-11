import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../incident/data/incident_repository.dart';

enum IncidentStatus { idle, counting, creating, active, canceled, error }

class IncidentState {
  final IncidentStatus status;
  final int countdown;
  final int? id;
  final String? message;
  const IncidentState({this.status = IncidentStatus.idle, this.countdown = 0, this.id, this.message});
  IncidentState copyWith({IncidentStatus? status, int? countdown, int? id, String? message}) =>
      IncidentState(status: status ?? this.status, countdown: countdown ?? this.countdown, id: id ?? this.id, message: message);
}

final incidentRepoProvider = Provider((_) => IncidentRepository());
final incidentControllerProvider = StateNotifierProvider<IncidentController, IncidentState>((ref) =>
    IncidentController(ref.read(incidentRepoProvider)));

class IncidentController extends StateNotifier<IncidentState> {
  final IncidentRepository _repo;
  Timer? _timer;
  IncidentController(this._repo) : super(const IncidentState());

  void startCountdown() {
    state = const IncidentState(status: IncidentStatus.counting, countdown: 5);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.countdown - 1;
      if (left <= 0) {
        t.cancel();
        _create();
      } else {
        state = state.copyWith(countdown: left);
      }
    });
  }

  void cancelCountdown() {
    _timer?.cancel();
    state = const IncidentState(status: IncidentStatus.idle);
  }

  Future<void> _create() async {
    try {
      state = state.copyWith(status: IncidentStatus.creating);
      final id = await _repo.createIncident();
      state = state.copyWith(status: IncidentStatus.active, id: id);
    } catch (e) {
      state = state.copyWith(status: IncidentStatus.error, message: e.toString());
    }
  }

  Future<void> cancelActive(String pin) async {
    if (state.id == null) return;
    await _repo.cancelIncident(state.id!, pin);
    state = const IncidentState(status: IncidentStatus.canceled);
  }
}

