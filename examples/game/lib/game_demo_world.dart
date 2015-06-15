part of game;

// Random generator
Math.Random _rand = new Math.Random();

const double _gameSizeWidth = 1024.0;
const double _gameSizeHeight = 1024.0;

const double _shipRadius = 30.0;
const double _lrgAsteroidRadius = 40.0;
const double _medAsteroidRadius = 20.0;
const double _smlAsteroidRadius = 10.0;
const double _maxAsteroidSpeed = 1.0;

const int _lifeTimeLaser = 50;

class GameDemoWorld extends NodeWithSize {

  // Images
  Image _imgBg;
  Image _imgAsteroid;
  Image _imgShip;
  Image _imgLaser;

  // Inputs
  double _joystickX = 0.0;
  double _joystickY = 0.0;
  bool _fire;

  Ship _ship;
  List<Asteroid> _asteroids = [];
  List<Laser> _lasers = [];
  
  GameDemoWorld(ImageMap images) : super.withSize(new Size(_gameSizeWidth, _gameSizeHeight)) {

    // Fetch images
    _imgBg = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png"];
    _imgAsteroid = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png"];
    _imgShip = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png"];
    _imgLaser = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/laserBlue.png"];

    // Add some asteroids to the game world
    for (int i = 0; i < 5; i++) {
      addAsteroid(AsteroidSize.large);
    }
    for (int i = 0; i < 5; i++) {
      addAsteroid(AsteroidSize.medium);
    }

    // Add ship
    addShip();
  }

  // Methods for adding game objects

  void addBackground() {
    Sprite sprtBg = new Sprite.withImage(_imgBg);
    sprtBg.size = new Size(_gameSizeWidth, _gameSizeHeight);
    sprtBg.pivot = Point.origin;
    this.addChild(sprtBg);
  }
  
  void addAsteroid(AsteroidSize size, [Point pos]) {
    Asteroid asteroid = new Asteroid.withImage(_imgAsteroid, size);
    asteroid.zPosition = 1.0;
    if (pos != null) asteroid.position = pos;
    this.addChild(asteroid);
    _asteroids.add(asteroid);
  }

  void addShip() {
    Ship ship = new Ship.withImage(_imgShip);
    ship.zPosition = 10.0;
    this.addChild(ship);
    _ship = ship;
  }

  void addLaser() {
    Laser laser = new Laser.withImage(_imgLaser, _ship);
    laser.zPosition = 8.0;
    _lasers.add(laser);
    this.addChild(laser);
  }
  
  void update(double dt) {
    // Move asteroids
    for (Asteroid asteroid in _asteroids) {
      asteroid.position = pointAdd(asteroid.position, asteroid._movementVector);
    }

    // Move lasers and remove expired lasers
    for (int i = _lasers.length - 1; i >= 0; i--) {
      Laser laser = _lasers[i];
      laser.move();
      if (laser._frameCount > _lifeTimeLaser) {
        laser.removeFromParent();
        _lasers.removeAt(i);
      }
    }

    // Apply thrust to ship
    if (_joystickX != 0.0 || _joystickY != 0.0) {
      _ship.thrust(_joystickX, _joystickY);
    }

    // Move ship
    _ship.move();

    // Check collisions between asteroids and lasers
    for (int i = _lasers.length -1; i >= 0; i--) {
      // Iterate over all the lasers
      Laser laser = _lasers[i];

      for (int j = _asteroids.length - 1; j >= 0; j--) {
        // Iterate over all the asteroids
        Asteroid asteroid = _asteroids[j];

        // Check for collision
        if (pointQuickDist(laser.position, asteroid.position) < laser.radius + asteroid.radius) {
          // Remove laser
          laser.removeFromParent();
          _lasers.removeAt(i);

          // Add asteroids
          if (asteroid._asteroidSize == AsteroidSize.large) {
            for (int a = 0; a < 3; a++) addAsteroid(AsteroidSize.medium, asteroid.position);
          }
          else if (asteroid._asteroidSize == AsteroidSize.medium) {
            for (int a = 0; a < 5; a++) addAsteroid(AsteroidSize.small, asteroid.position);
          }

          // Remove asteroid
          asteroid.removeFromParent();
          _asteroids.removeAt(j);
          break;
        }
      }
    }

    // Move objects to center camera and warp objects around the edges
    centerCamera();
    warpObjects();
  }

  void centerCamera() {
    const cameraDampening = 0.1;
    Point delta = new Point(_gameSizeWidth/2 - _ship.position.x, _gameSizeHeight/2 - _ship.position.y);
    delta = pointMult(delta, cameraDampening);

    for (Node child in children) {
      child.position = pointAdd(child.position, delta);
    }
  }

  void warpObjects() {
    for (Node child in children) {
      if (child.position.x < 0) child.position = pointAdd(child.position, new Point(_gameSizeWidth, 0.0));
      if (child.position.x >= _gameSizeWidth) child.position = pointAdd(child.position, new Point(-_gameSizeWidth, 0.0));
      if (child.position.y < 0) child.position = pointAdd(child.position, new Point(0.0, _gameSizeHeight));
      if (child.position.y >= _gameSizeHeight) child.position = pointAdd(child.position, new Point(0.0, -_gameSizeHeight));
    }
  }

  // Handling controls

  void controlSteering(double x, double y) {
    _joystickX = x;
    _joystickY = y;
  }

  void controlFire() {
    addLaser();
  }
}

// Game objects

enum AsteroidSize {
  small,
  medium,
  large,
}

class Asteroid extends Sprite {
  Point _movementVector;
  AsteroidSize _asteroidSize;
  double _radius;

  double get radius {
    if (_radius != null) return _radius;
    if (_asteroidSize == AsteroidSize.small) _radius = _smlAsteroidRadius;
    else if (_asteroidSize == AsteroidSize.medium) _radius = _medAsteroidRadius;
    else if (_asteroidSize == AsteroidSize.large) _radius = _lrgAsteroidRadius;
    return _radius;
  }

  Asteroid.withImage(Image img, AsteroidSize this._asteroidSize) : super.withImage(img) {
    size = new Size(radius * 2.0, radius * 2.0);
    position = new Point(_gameSizeWidth * _rand.nextDouble(), _gameSizeHeight * _rand.nextDouble());
    rotation = 360.0 * _rand.nextDouble();

    _movementVector = new Point(_rand.nextDouble() * _maxAsteroidSpeed * 2 - _maxAsteroidSpeed,
                                _rand.nextDouble() * _maxAsteroidSpeed * 2 - _maxAsteroidSpeed);
  }
}

class Ship extends Sprite {
  Vector2 _movementVector;
  double _rotationTarget;

  Ship.withImage(Image img) : super.withImage(img) {
    _movementVector = new Vector2.zero();
    rotation = _rotationTarget = 270.0;

    // Create sprite
    size = new Size(_shipRadius * 2.0, _shipRadius * 2.0);
    position = new Point(_gameSizeWidth/2.0, _gameSizeHeight/2.0);
  }

  void thrust(double x, double y) {
    _rotationTarget = convertRadians2Degrees(Math.atan2(y, x));
    Vector2 directionVector = new Vector2(x, y).normalize();
    _movementVector.addScaled(directionVector, 1.0);
  }

  void move() {
    position = new Point(position.x + _movementVector[0], position.y + _movementVector[1]);
    _movementVector.scale(0.9);

    rotation = dampenRotation(rotation, _rotationTarget, 0.1);
  }
}

class Laser extends Sprite {
  int _frameCount = 0;
  Point _movementVector;
  double radius = 10.0;

  Laser.withImage(Image img, Ship ship) : super.withImage(img) {
    size = new Size(20.0, 20.0);
    position = ship.position;
    rotation = ship.rotation + 90.0;
    transferMode = TransferMode.plusMode;
    double rotRadians = convertDegrees2Radians(rotation);
    _movementVector = pointMult(new Point(Math.sin(rotRadians), -Math.cos(rotRadians)), 10.0);
    _movementVector = new Point(_movementVector.x + ship._movementVector[0], _movementVector.y + ship._movementVector[1]);
  }

  bool move() {
    position = pointAdd(position, _movementVector);
    _frameCount++;
  }
}

// Convenience methods

Point pointAdd(Point a, Point b) {
  return new Point(a.x+ b.x, a.y + b.y);
}

Point pointMult(Point a, double multiplier) {
  return new Point(a.x * multiplier, a.y * multiplier);
}

double dampenRotation(double src, double dst, double dampening) {
  double delta = dst - src;
  while (delta > 180.0) delta -= 360;
  while (delta < -180) delta += 360;
  delta *= dampening;

  return src + delta;
}

double pointQuickDist(Point a, Point b) {
  double dx = a.x - b.x;
  double dy = a.y - b.y;
  if (dx < 0.0) dx = -dx;
  if (dy < 0.0) dy = -dy;
  if (dx > dy) {
    return dx + dy/2.0;
  }
  else {
    return dy + dx/2.0;
  }
}