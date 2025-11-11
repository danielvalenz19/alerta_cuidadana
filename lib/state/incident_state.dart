import 'package:flutter/foundation.dart';

enum IncidentPhase { idle, countdown, active }

class IncidentState extends ChangeNotifier {
  IncidentPhase phase = IncidentPhase.idle;
  int countdown = 5;
  String? currentIncidentId;

  void startCountdown([int seconds = 5]) {
    countdown = seconds;
    phase = IncidentPhase.countdown;
    notifyListeners();
  }

  void tickCountdown() {
    if (phase != IncidentPhase.countdown) return;
    if (countdown <= 0) return;
    countdown -= 1;
    notifyListeners();
  }

  void setActive(String incidentId) {
    currentIncidentId = incidentId;
    phase = IncidentPhase.active;
    notifyListeners();
  }

  void reset() {
    currentIncidentId = null;
    countdown = 5;
    phase = IncidentPhase.idle;
    notifyListeners();
  }
}
