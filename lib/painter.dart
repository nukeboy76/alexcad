import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor.dart';
import 'input.dart';
import 'inspector.dart';
import 'window.dart';


class Painter {
    Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

    Paint paintStroke = Paint()
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

    void setPaint({Color color = Colors.black, double width = 2}) {
        paint.color = color;
        paint.strokeWidth = width;
    }

    void setPaintStroke({Color color = Colors.black, double width = 2}) {
        paintStroke.color = color;
        paintStroke.strokeWidth = width;
    }

    void drawText({
        required Window window,
        required String text,
        double fontSize = 14,
        required Color bgColor,
        required Color textColor,
        required Offset textOffset,
        bool outline = false,
        bool centerAlignX = false,
        bool centerAlignY = false,
    }) {
        final textStyle = TextStyle(
            color: textColor,
            fontSize: fontSize,
            background: Paint()..color = bgColor,
            shadows: outline ? [
                Shadow( // bottomLeft
                    offset: Offset(-1.5, -1.5),
                    color: Colors.white
                ),
                Shadow( // bottomRight
                    offset: Offset(1.5, -1.5),
                    color: Colors.white
                ),
                Shadow( // topRight
                    offset: Offset(1.5, 1.5),
                    color: Colors.white
                ),
                Shadow( // topLeft
                    offset: Offset(-1.5, 1.5),
                    color: Colors.white
                ),
            ] : null,
        );
        final textSpan = TextSpan(
            text: text,
            style: textStyle,
        );
        final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
        )..layout(
            minWidth: 0,
            maxWidth: window.width,
        );

        textPainter.paint(
            window.canvas,
            Offset(
                centerAlignX ? textOffset.dx - textPainter.width / 2 : textOffset.dx,
                centerAlignY ? textOffset.dy - textPainter.height / 2 : textOffset.dy,
            ),
        );
    }

    void drawLine(Window window, Offset start, Offset end) {
        window.canvas.drawLine(start, end, paint);
    }

    void drawTriangle(Window window, Offset a, Offset b, Offset c) {
        var path = Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(c.dx, c.dy)
            ..close();
        window.canvas.drawPath(path, paint);
    }

    void drawQuad(Window window, Offset a, Offset b, Offset c, Offset d) {
        a = window.worldToScreen(a);
        b = window.worldToScreen(b);
        c = window.worldToScreen(c);
        d = window.worldToScreen(d);
        var path = Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(d.dx, d.dy)
            ..lineTo(c.dx, c.dy)
            ..close();
        window.canvas.drawPath(path, paint);
    }

    void drawRect(Window window, Rect rect) {
        window.canvas.drawRect(rect, paint);
    }

    void drawCircle(Window window, Offset c, double r) {
        window.canvas.drawCircle(c, r, paint);
    }
}
