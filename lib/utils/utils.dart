import 'dart:math';
import 'package:flutter/material.dart';

final List<Offset> directions = [
    const Offset(1, 0),
    const Offset(0, 1),
];

final List<Offset> allDirections = [
    const Offset(1, 0),
    const Offset(-1, 0),
    const Offset(0, 1),
    const Offset(0, -1),
];

bool xAxisEqual(Offset a, Offset b) => a.dx == b.dx;
bool yAxisEqual(Offset a, Offset b) => a.dy == b.dy;
bool xAscendingAB(Offset a, Offset b) => (b.dx - a.dx) > 0;
bool yAscendingAB(Offset a, Offset b) => (b.dy - a.dy) > 0;

double triangleArea(Offset a, Offset b, Offset c) {
    return ((a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy)) / 2).abs();
}

bool isPointInQuad(Offset p, Offset a, Offset b, Offset c, Offset d) {
    final pab = triangleArea(p, a, b);
    final pbc = triangleArea(p, c, b);
    final pcd = triangleArea(p, c, d);
    final pda = triangleArea(p, a, d);

    final rectArea = (b - a).distance * (d - b).distance;
    return (pab + pbc + pcd + pda) < rectArea;
}

bool isPointInRect(Offset p, Offset lb, Offset rt) {
    return Rect.fromPoints(lb, rt).contains(p);
}

bool isPointInCircle(Offset p, Offset c, double r) {
    return sqrt(pow(p.dx - c.dx, 2) + pow(p.dy - c.dy, 2)) < r;
}

Offset rotatePoint(Offset center, Offset point, double angle) {
    final double s = sin(angle);
    final double c = cos(angle);
    point = Offset(point.dx - center.dx, point.dy - center.dy);

    return Offset(point.dx * c - point.dy * s + center.dx, point.dx * s + point.dy * c + center.dy);
}

int clampInt(int value, int lower, int upper) {
    return value.clamp(lower, upper).toInt();
}

double lerpInt(int a, int b, double t) {
    final newA = a.toDouble();
    final newB = b.toDouble();
    return newA * (1.0 - t) + newB * t;
}

double lerpDoble(double a, double b, double t) {
    return a * (1.0 - t) + b * t;
}

Offset lerpOffset(Offset a, Offset b, double t) {
    return Offset(a.dx * (1.0 - t) + b.dx * t, a.dy * (1.0 - t) + b.dy * t);
}

Offset avgPoint(List<Offset> points) {
    return points.reduce((a, b) => a + b) / points.length.toDouble();
}

double floorToPowerOfTwo(double value) {
    bool inv = value >= 1;
    int x = inv ? value.toInt() : (1 / value).toInt();

    int t = 1 << 48;
    while (x < t) { t >>= 1; }

    double result = t.toDouble();
    return inv ? result : 1 / result;
}

double snap(double value, double snapLevel) {
    return (value / snapLevel).round() * snapLevel;
}

Size calcTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaleFactor: WidgetsBinding.instance.window.textScaleFactor,
    )..layout();
    return textPainter.size;
}
