import 'dart:math';

import 'package:flutter/material.dart';

import 'utils/colors.dart';


const cianColor = CadColor(Color(0xff48e9f6));
const amberColor = CadColor(Color(0xfffab167));
const pinkColor = CadColor(Color(0xffe63484));
const purpleColor = CadColor(Color(0xff7d25ca));

const double twoPI = pi / 2;

class CadColor {
    const CadColor(this.color);

    final Color color;

    Color darker(double scale) => lerpColorARGB(color, Colors.black, scale);
    Color lighter(double scale) => lerpColorARGB(color, Colors.white, scale);
    Color withBrightness(double scale) => scale >= 0 ? lighter(scale) : darker(scale);

    Color withAlpha(int a) {
        return Color.fromARGB(a, color.red, color.green, color.blue);
    }

    Color withOpacity(double opacity) {
        assert(opacity >= 0.0 && opacity <= 1.0);
        return withAlpha((255.0 * opacity).round());
    }
}


// http://dev.thi.ng/gradients/
// [0.938,0.328,0.718],[0.659,0.438,0.328],[0.388,0.388,0.296],[2.486,2.426,0.116]

Color palette(double t) {
    print(t);
    return pal(
        t,
        //[0.610, 0.498, 0.650], [0.388, 0.498, 0.350], [0.530, 0.498, 0.620], [3.438, 3.012, 4.025], // main
        //[0.500, 0.500, 0.500], [0.500, 0.500, 0.500], [0.800, 0.800, 0.500], [0.000, 0.200, 0.500], // orange-blue
        [0.500, 0.500, 0.500], [0.100, 0.500, 0.500], [1.000, 1.000, 1.000], [0.000, 0.333, 0.667]
    );
}

Color pal(double t, List<double> a, List<double> b, List<double> c, List<double> d) {
    List<int> result = [];
    for (int i = 0; i < 3; i++) {
        result.add(((a[i] + b[i] * cos(twoPI * (c[i] * t + d[i]))) * 255).toInt());
    }
    return Color.fromRGBO(result[0], result[1], result[2], 1);
}
