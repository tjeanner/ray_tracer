import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:equations/equations.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ray Tracer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _screenHeight;
  double _screenWidth;
  double _devicePixelRatio;

  @override
  void initState() {
    super.initState();
    //SystemChrome.setEnabledSystemUIOverlays([]);
    //SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  _setScreenSize(double height, double width, devicePixelRatio) {
    setState(() {
      _screenHeight = height;
      _screenWidth = width;
      _devicePixelRatio = devicePixelRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screenWidth == null) {
      _setScreenSize(
          MediaQuery.of(context).size.height,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).devicePixelRatio);
    }
    return Scaffold(
      body: _screenWidth == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black,
              child: CustomPaint(
                painter: RayTracerPainter(
                    screenHeight: _screenHeight,
                    screenWidth: _screenWidth,
                    devicePixelRatio: _devicePixelRatio),
              ),
            ),
    );
  }
}

enum objectType { sphere, plane, cylindre, cone, torus }

class Object {
  objectType type;
  double radius;
  //double radius2;
  Vector o;
  Vector norm;
  Vector norm2;
  Color col;
  //double k_diff;
  //double transp;
  //double k_spec;
  //double k_phong;
  //double reflect;
  //double refract;
  bool isLight;

  Object(objectType type, double radius, Vector o, Vector norm, Vector norm2,
      Color col, bool isLight) {
    this.type = type;
    this.radius = radius;
    this.o = o;
    this.norm = norm;
    this.norm2 = norm2;
    this.col = col;
    this.isLight = isLight;
  }
}

class Vector {
  double x;
  double y;
  double z;

  Vector(double x, double y, double z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  double getLength() {
    return sqrt(pow(this.x, 2) + pow(this.y, 2) + pow(this.z, 2));
  }

  Vector getVectorUnit() {
    double norme = this.getLength();
    return Vector(this.x / norme, this.y / norme, this.z / norme);
  }

  Vector getVectorInv() {
    return Vector(-this.x, -this.y, -this.z);
  }

  Vector add(Vector v) {
    return Vector(this.x + v.x, this.y + v.y, this.z + v.z);
  }

  Vector subs(Vector v) {
    return Vector(this.x - v.x, this.y - v.y, this.z - v.z);
  }

  Vector mult(double n) {
    return Vector(this.x * n, this.y * n, this.z * n);
  }

  double scal(Vector v) {
    return this.x * v.x + this.y * v.y + this.z * v.z;
  }

  Vector prod(Vector v) {
    return Vector(this.y * v.z - this.z * v.y, -(this.x * v.z - this.z * v.x),
        this.x * v.y - this.y * v.x);
  }
}

class Line {
  Vector point;
  Vector vector;

  Line(Vector point, Vector vector) {
    this.point = point;
    this.vector = vector;
  }
}

class Light {
  Vector pos;
  double intensity;

  Light(Vector pos, double intensity) {
    this.pos = pos;
    this.intensity = intensity;
  }
}

class Hit {
  Vector initRaypos;
  Vector initRay;
  Object obj;

  Hit(Vector initRayPos, Vector initRay, Object obj) {
    this.initRaypos = initRayPos;
    this.initRay = initRay;
    this.obj = obj;
  }
}

class RayTracerPainter extends CustomPainter {
  final double screenHeight;
  final double screenWidth;
  final double devicePixelRatio;
  Vector _myCamPos = Vector(300, 0, -6000);
  Vector _mycamVector1 = Vector(0, 0, 1);
  Vector _mycamVector2 = Vector(-1, 0, 0);
  Vector _mycamVector3 = Vector(0, 1, 0);
  double torad  = pi / 180.0;
  double todeg  = 180.0 / pi;
  double dist = 683.4285714285714 / tan(30.0 * (pi / 180.0));
  List<Object> objects = [
    Object(objectType.sphere, 300, Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Colors.red, false),
    Object(objectType.sphere, 75, Vector(200, -200, 0), Vector(0, 0, 0), Vector(0, 0, 0), Colors.blue, false),
    Object(objectType.sphere, 50, Vector(200, 170, -100), Vector(0, 0, 0), Vector(0, 0, 0), Colors.blue, false),
    Object(objectType.sphere, 50, Vector(200, -120, -300), Vector(0, 0, 0), Vector(0, 0, 0), Colors.yellow, false),
    Object(objectType.sphere, 200, Vector(500, -100, 0), Vector(0, 0, 0), Vector(0, 0, 0), Colors.green, false),
    //Object(objectType.plane, 200, Vector(100, 0, 0), Vector(1, 0, 0), Vector(0, 1, 0), Colors.yellow),
    //Object(objectType.plane, 200, Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 0, 0), Colors.blue),
    //Object(objectType.plane, 200, Vector(0, 0, 4000), Vector(0, 1, 0), Vector(1, 0, 0), Colors.green),
    //Object(objectType.sphere, 18500, Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Colors.green)
  ];
  List<Light> lights = [
    Light(Vector(1000, 0, -300), 1.0),
    Light(Vector(1000, -1000, -300), 1.0),
    //Light(Vector(500, -200, -300), 0.4)
  ];
  double _lumAmb = 0.15;
  double _pas = 1.0;
  //Vector _v = Vector(0, 0, 0);

  RayTracerPainter({screenHeight, screenWidth, devicePixelRatio})
      : this.screenHeight = screenHeight,
        this.screenWidth = screenWidth,
        this.devicePixelRatio = devicePixelRatio;

  double resolve(Vector math) {
    Vector res = Vector(0, 0, 0);
  math.z = math.y * math.y - 4.0 * math.x * math.z;
  if (math.z < 0.0) {
    return null;
  }
  res.y = (-math.y + sqrt(math.z)) / (2.0 * math.x);
  res.x = (-math.y - sqrt(math.z)) / (2.0 * math.x);
  if (res.y < 0.0) {
    return null;
  }
  res.z = (res.x > 0.0) ? res.x : res.y;
  return res.z;
  }

  double _getSmallestPositiveDistanceLight(Line line, int light) {
    double tmp = 0.0;
      Vector objectOrigin2cam = line.point.subs(lights[light].pos);
      Vector math = Vector(0, 0, 0);
      math.x = line.vector.scal(line.vector);
      math.y = 2.0 * line.vector.scal(objectOrigin2cam);
      math.z = objectOrigin2cam.scal(objectOrigin2cam) - 1600;
      if ((tmp = resolve(math)) != null) {
        return tmp;
      }
    return -1;
  }

  double _getSmallestPositiveDistance(Line line, Object object) {
    double tmp = 0.0;
    if(object.type == objectType.sphere) {
      Vector objectOrigin2cam = line.point.subs(object.o);
      Vector math = Vector(0, 0, 0);
      math.x = line.vector.scal(line.vector);
      math.y = 2.0 * line.vector.scal(objectOrigin2cam);
      math.z = objectOrigin2cam.scal(objectOrigin2cam) - object.radius * object.radius;
      if ((tmp = resolve(math)) != null) {
        return tmp;
      }
    } else if (object.type == objectType.plane) {
      Vector		tmp;
      double	opti_a;
      double	opti_b;

      tmp = line.vector.scal(object.norm) > 0.000 ?
      object.norm : object.norm.getVectorInv();
      opti_a = line.point.subs(object.o).scal(tmp);
      opti_b = line.vector.scal(tmp);
      if (opti_b == 0.0 || ((opti_a > 0.0 && opti_b < 0.0) || (opti_a <= 0.0 && opti_b >= 0.0)))
        return (0);
      tmp.z = -1.000 * opti_a / opti_b;
    return tmp.z > 0.0 ? tmp.z : -1;
    }
    return -1;
  }

  Hit _getCollision(Vector start, Vector dir) {
    Line line = Line(start, dir);
    var index = 0;
    double distance = 0.0;
    double distanceTmp = 0.0;
    Hit hit;
    while(index < objects.length) {
      distanceTmp = _getSmallestPositiveDistance(line, objects[index]);
      if(distanceTmp >= 0.0 && (distance > distanceTmp || distance == 0.0)) {
        distance = distanceTmp;
        hit = Hit(line.point, line.vector.getVectorUnit().mult(distanceTmp), objects[index]);
      }
      index++;
    }
    return hit;
  }

  Color _getColor(double a, double i) {
    Hit hit = _getCollision(_myCamPos, _mycamVector1.mult(dist).add(_mycamVector3.getVectorInv().mult((a - this.screenWidth / 2.0) / _mycamVector3.getLength()).add(_mycamVector2.mult((this.screenHeight / 2.0 - i) / _mycamVector2.getLength()))).getVectorUnit());
    var index = 0;
    List<double> lightsIntensitys = List.filled(lights.length, 0.0);
    Vector norm = Vector(0, 0, 0);
    while (index < lights.length){
      if (hit != null) {
        if (hit.obj.type == objectType.sphere) {
          norm = hit.initRaypos.add(hit.initRay)
              .subs(hit.obj.o)
              .getVectorUnit();
        } else if (hit.obj.type == objectType.plane) {
          norm = hit.obj.norm;
        }
        Vector surf2Light = lights[index].pos
            .subs(hit.initRaypos.add(hit.initRay)).getVectorUnit();
        Hit betweenLightAndSurf = _getCollision(hit.initRaypos.add(hit.initRay).add(norm.mult(0.000001)), surf2Light);
        if(hit.obj.isLight) {
          return Colors.white;
        }
        else if (betweenLightAndSurf == null || betweenLightAndSurf.initRay.getLength() > hit.initRaypos.add(hit.initRay).subs(_myCamPos).getLength() || betweenLightAndSurf.obj.isLight) {
          double angle = acos(norm.scal(surf2Light.getVectorUnit()) / (norm.getLength() * surf2Light.getVectorUnit().getLength())) * todeg;
          double result = lights[index].intensity * 1.0 * cos(angle * torad);
          if(angle < 0 || angle > 90){
            //return Color.fromRGBO((hit.obj.col.red * _lumAmb).toInt(), (hit.obj.col.green * _lumAmb).toInt(), (hit.obj.col.blue * _lumAmb).toInt(), 1.0);
            lightsIntensitys[index] = _lumAmb;
          }
          //return Color.fromRGBO((hit.obj.col.red * result * (1.0 - _lumAmb) + _lumAmb * hit.obj.col.red).toInt(), (hit.obj.col.green * result * (1.0 - _lumAmb) + _lumAmb * hit.obj.col.green).toInt(), (hit.obj.col.blue * result * (1.0 - _lumAmb) + _lumAmb * hit.obj.col.blue).toInt(), 1.0);
          else {
            lightsIntensitys[index] = result * (1.0 - _lumAmb) + _lumAmb;
          }
        }
        //return Color.fromRGBO((hit.obj.col.red * _lumAmb).toInt(), (hit.obj.col.green * _lumAmb).toInt(), (hit.obj.col.blue * _lumAmb).toInt(), 1.0);
        else {
          lightsIntensitys[index] = _lumAmb;
        }
      } else {
        return Colors.black;
      }
      index++;
    }
    index = 0;
    double res = 0.0;
    while (index < lights.length) {
      res += lightsIntensitys[index];
      index++;
    }
    res /= lights.length;
    return Color.fromRGBO((hit.obj.col.red * res).toInt(), (hit.obj.col.green * res).toInt(), (hit.obj.col.blue * res).toInt(), 1.0);
  }

  _addLights2Scene() {
    int i = 0;
    int delta = objects.length;
    while (i < lights.length) {
      objects.add(Object(objectType.sphere, 20, lights[i].pos, Vector(0, 0, 0), Vector(0, 0, 0), Colors.white, true));
      i++;
    }
  }

  _removeLightsFromScene() {
    int i = lights.length;
    while (i > 0) {
      objects.removeAt(objects.length - i);
      i--;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _addLights2Scene();
    double a = 0;
    while (a * _pas < this.screenWidth) {
      double i = 0;
      while (i * _pas < this.screenHeight) {
        Paint paint = Paint()
          ..color = _getColor(a * _pas + 0.5 * _pas, i * _pas + 0.5 * _pas)
          ..strokeWidth = 1 / this.devicePixelRatio
          ..isAntiAlias = false;
        canvas.drawRect(Offset(a * _pas, i * _pas) & Size(_pas * _pas, _pas * _pas), paint);
        i += _pas;
      }
      a += _pas;
    }
    _removeLightsFromScene();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
