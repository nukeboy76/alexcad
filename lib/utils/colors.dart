import 'package:flutter/material.dart';
import 'utils.dart';


Color lerpColorARGB(a, b, alpha) {
    return Color.fromARGB(
        clampInt(lerpInt(a.alpha, b.alpha, alpha).toInt(), 0, 255),
        clampInt(lerpInt(a.red, b.red, alpha).toInt(), 0, 255),
        clampInt(lerpInt(a.green, b.green, alpha).toInt(), 0, 255),
        clampInt(lerpInt(a.blue, b.blue, alpha).toInt(), 0, 255),
    );
}

Color lighter(Color color, double scale) => lerpColorARGB(color, Colors.white, scale);
Color darker(Color color, double scale) => lerpColorARGB(color, Colors.black, scale);

Color withBrightness(Color color, double scale) => scale >= 0 ? lighter(color, scale) : darker(color, scale.abs());
