import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Window {
    late Canvas canvas;
    late Size _size;

    double zoom = 20;
    Offset pan = Offset(500, 500);
    
    final double zoomMin = 5.00;
    final double zoomMax = 40.0;

    double get width => _size.width;
    double get height => _size.height;
    double get aspectRatio => width / height;
    Offset get size => Offset(width, height);
    Offset get center => size / 2;

    void init(Canvas canvas, Size size) {
        this.canvas = canvas;
        this._size = size;
    }

    Offset worldToScreen(Offset worldPoint) =>
        Offset(worldPoint.dx * zoom + pan.dx, -worldPoint.dy * zoom + pan.dy);
    Offset screenToWorld(Offset screenPoint) =>
        Offset((screenPoint.dx - pan.dx) / zoom, -(screenPoint.dy - pan.dy) / zoom);
}
