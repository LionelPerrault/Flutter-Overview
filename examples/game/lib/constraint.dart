part of sprites;

abstract class Constraint {
  void preUpdate(Node node, double dt) {
  }

  void constrain(Node node, double dt);
}

double _dampenRotation(double src, double dst, double dampening) {
  double delta = dst - src;
  while (delta > 180.0) delta -= 360;
  while (delta < -180) delta += 360;
  delta *= dampening;

  return src + delta;
}

class ConstraintRotationToMovement {
  ConstraintRotationToMovement([this.dampening]);
  final double dampening;

  Point _lastPosition;

  void preUpdate(Node node, double dt) {
    _lastPosition = node.position;
  }

  void constrain(Node node, double dt) {
    assert(_lastPosition != null);
    if (_lastPosition == node.position) return;

    // Get the target angle
    Offset offset = node.position - _lastPosition;
    double target = degrees(GameMath.atan2(offset.dy, offset.dx));

    if (dampening == null)
      node.rotation = target;
    else
      node.rotation = _dampenRotation(node.rotation, target, dampening);
  }
}
