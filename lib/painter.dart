import 'package:flutter/material.dart';

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
        Color outlineColor = Colors.white,
        double outlineSize = 1.5,
        bool outline = false,
        bool centerAlignX = false,
        bool centerAlignY = false,
        String? fontFamily,
        FontStyle? fontStyle,
    }) {
        final textStyle = TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            background: Paint()..color = bgColor,
            shadows: outline ? [
                Shadow( // bottomLeft
                    offset: Offset(-outlineSize, -outlineSize),
                    color: outlineColor,
                ),
                Shadow( // bottomRight
                    offset: Offset(outlineSize, -outlineSize),
                    color: outlineColor,
                ),
                Shadow( // topRight
                    offset: Offset(outlineSize, outlineSize),
                    color: outlineColor,
                ),
                Shadow( // topLeft
                    offset: Offset(-outlineSize, outlineSize),
                    color: outlineColor,
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

    Path getQuadPath(Window window, Offset a, Offset b, Offset c, Offset d) {
        a = window.worldToScreen(a);
        b = window.worldToScreen(b);
        c = window.worldToScreen(c);
        d = window.worldToScreen(d);
        return Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(d.dx, d.dy)
            ..lineTo(c.dx, c.dy)
            ..close();
    }

    void drawQuad(Window window, Offset a, Offset b, Offset c, Offset d) {
        window.canvas.drawPath(getQuadPath(window, a, b, c, d), paint);
    }

    void drawQuadStroke(Window window, Offset a, Offset b, Offset c, Offset d) {
        window.canvas.drawPath(getQuadPath(window, a, b, c, d), paintStroke);
    }

    void drawRect(Window window, Rect rect) {
        window.canvas.drawRect(rect, paint);
    }

    void drawRectWithPaint(Window window, Rect rect, Paint p) {
        window.canvas.drawRect(rect, p);
    }

    void drawRectStroke(Window window, Rect rect) {
        window.canvas.drawRect(rect, paintStroke);
    }

    void drawCircle(Window window, Offset c, double r) {
        window.canvas.drawCircle(c, r, paint);
    }

    void drawCircleStroke(Window window, Offset c, double r) {
        window.canvas.drawCircle(c, r, paintStroke);
    }
}
