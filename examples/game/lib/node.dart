part of sprites;

double convertDegrees2Radians(double degrees) => degrees * Math.PI/180.8;

double convertRadians2Degrees(double radians) => radians * 180.0/Math.PI;

class Node {

  // Member variables

  SpriteBox _spriteBox;
  Node _parent;

  Point _position;
  double _rotation;
  
  bool _isMatrixDirty;
  Matrix4 _transformMatrix;
  Matrix4 _transformMatrixFromWorld;

  double _scaleX;
  double _scaleY;

  bool visible;

  double _zPosition;
  int _addedOrder;
  int _childrenLastAddedOrder;
  bool _childrenNeedSorting;

  bool paused = false;

  List<Node>_children;

  // Constructors
  
  Node() {
    _rotation = 0.0;
    _position = Point.origin;
    _scaleX = _scaleY = 1.0;
    _isMatrixDirty = false;
    _transformMatrix = new Matrix4.identity();
    _children = [];
    _childrenNeedSorting = false;
    _childrenLastAddedOrder = 0;
    _zPosition = 0.0;
    visible = true;
  }

  // Property setters and getters

  SpriteBox get spriteBox => _spriteBox;

  Node get parent => _parent;
  
  double get rotation => _rotation;
  
  void set rotation(double rotation) {
    _rotation = rotation;
    _isMatrixDirty = true;
  }

  Point get position => _position;
  
  void set position(Point position) {
    _position = position;
    _isMatrixDirty = true;
  }

  double get zPosition => _zPosition;

  void set zPosition(double zPosition) {
    _zPosition = zPosition;
    if (_parent != null) {
      _parent._childrenNeedSorting = true;
    }
  }

  double get scale {
    assert(_scaleX == _scaleY);
    return _scaleX;
  }

  void set scale(double scale) {
    _scaleX = _scaleY = scale;
    _isMatrixDirty = true;
  }

  List<Node> get children => _children;

  // Adding and removing children

  void addChild(Node child) {
    assert(child._parent == null);

    _childrenNeedSorting = true;
    _children.add(child);
    child._parent = this;
    child._spriteBox = this._spriteBox;
    _childrenLastAddedOrder += 1;
    child._addedOrder = _childrenLastAddedOrder;
  }

  void removeChild(Node child) {
    if (_children.remove(child)) {
      child._parent = null;
      child._spriteBox = null;
    }
  }

  void removeFromParent() {
    assert(_parent != null);
    _parent.removeChild(this);
  }

  void removeAllChildren() {
    for (Node child in _children) {
      child._parent = null;
      child._spriteBox = null;
    }
    _children = [];
    _childrenNeedSorting = false;
  }

  // Calculating the transformation matrix
  
  Matrix4 get transformMatrix {
    if (!_isMatrixDirty) {
      return _transformMatrix;
    }
    
    double cx, sx, cy, sy;
    
    if (_rotation == 0.0) {
      cx = 1.0;
      sx = 0.0;
      cy = 1.0;
      sy = 0.0;
    }
    else {
      double radiansX = convertDegrees2Radians(_rotation);
      double radiansY = convertDegrees2Radians(_rotation);
      
      cx = Math.cos(radiansX);
      sx = Math.sin(radiansX);
      cy = Math.cos(radiansY);
      sy = Math.sin(radiansY);
    }

    // Create transformation matrix for scale, position and rotation
    _transformMatrix.setValues(cy * _scaleX, sy * _scaleX, 0.0, 0.0,
               -sx * _scaleY, cx * _scaleY, 0.0, 0.0,
               0.0, 0.0, 1.0, 0.0,
              _position.x, _position.y, 0.0, 1.0
    );
    
    return _transformMatrix;
  }

  // Transforms to other nodes

  Matrix4 _nodeToBoxMatrix() {
    assert(_spriteBox != null);

    Matrix4 t = transformMatrix;

    // Apply transforms from parents
    Node p = this.parent;
    while (p != null) {
      t = new Matrix4.copy(p.transformMatrix).multiply(t);
      p = p.parent;
    }

    // Apply transform from sprite box
    t = new Matrix4.copy(_spriteBox.transformMatrix).multiply(t);

    return t;
  }

  Matrix4 _boxToNodeMatrix() {
    assert(_spriteBox != null);

    Matrix4 t = _nodeToBoxMatrix();
    t.invert();

    return t;
  }

  Point convertPointToNodeSpace(Point boxPoint) {
    assert(boxPoint != null);
    assert(_spriteBox != null);

    Vector4 v =_boxToNodeMatrix().transform(new Vector4(boxPoint.x, boxPoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

  Point convertPointToBoxSpace(Point nodePoint) {
    assert(nodePoint != null);
    assert(_spriteBox != null);

    Vector4 v =_nodeToBoxMatrix().transform(new Vector4(nodePoint.x, nodePoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

  Point convertPointFromNode(Point point, Node node) {
    assert(node != null);
    assert(point != null);
    assert(_spriteBox != null);
    assert(_spriteBox == node._spriteBox);

    Point boxPoint = node.convertPointToBoxSpace(point);
    Point localPoint = convertPointToNodeSpace(boxPoint);

    return localPoint;
  }

  // Hit test

  bool hitTest(Point nodePoint) {
    assert(nodePoint != null);

    return false;
  }

  // Rendering
  
  void visit(PictureRecorder canvas) {
    if (!visible) return;

    prePaint(canvas);
    paint(canvas);
    visitChildren(canvas);
    postPaint(canvas);
  }
  
  void prePaint(PictureRecorder canvas) {
    canvas.save();

    // Get the transformation matrix and apply transform
    canvas.concat(transformMatrix.storage);
  }
  
  void paint(PictureRecorder canvas) {
    
  }
 
  void visitChildren(PictureRecorder canvas) {
    // Sort children primarily by zPosition, secondarily by added order
    if (_childrenNeedSorting) {
      _children.sort((Node a, Node b) {
        if (a._zPosition == b._zPosition) {
          return a._addedOrder - b._addedOrder;
        }
        else if (a._zPosition > b._zPosition) {
          return 1;
        }
        else {
          return -1;
        }
      });
      _childrenNeedSorting = false;
    }

    // Visit each child
    _children.forEach((child) => child.visit(canvas));
  }
  
  void postPaint(PictureRecorder canvas) {
    canvas.restore();
  }

  // Receiving update calls

  void update(double dt) {
  }

  void spriteBoxPerformedLayout() {
  }
}