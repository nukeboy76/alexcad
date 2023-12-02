import 'package:flutter/material.dart';

import 'utils/utils.dart';
import 'utils/colors.dart';


const cianColor = const CadColor(Color(0xff48e9f6));
const amberColor = const CadColor(Color(0xfffab167));
const pinkColor = const CadColor(Color(0xffe63484));
const purpleColor = const CadColor(Color(0xff7d25ca));


class CadColor {
    const CadColor(this.color);

    final Color color;

    Color darker(double scale) => lerpColorARGB(color, Colors.black, scale);
    Color lighter(double scale) => lerpColorARGB(color, Colors.white, scale);

    Color withAlpha(int a) {
      return Color.fromARGB(a, color.red, color.green, color.blue);
    }

    Color withOpacity(double opacity) {
      assert(opacity >= 0.0 && opacity <= 1.0);
      return withAlpha((255.0 * opacity).round());
    }
}
