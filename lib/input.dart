import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icons.dart';
import 'editor.dart';
import 'inspector.dart';
import 'painter.dart';
import 'window.dart';
import 'utils/utils.dart';


class Input {
    Input({
        this.mousePosWorld = const Offset(0, 0),
        this.mouseWorldDelta = const Offset(0, 0),
        this.mouseDelta = const Offset(0, 0),
        this.mouseDown = const Offset(0, 0),
        this.mouseUp = const Offset(0, 0),
        this.mouseWorldClick = const Offset(0, 0),
        this.isMouseDown = false,
    });

    final double _mouseSensitivity = 0.001;

    Offset mousePosWorld;
    Offset mouseWorldDelta;
    Offset mouseDelta;
    Offset mouseDown;
    Offset mouseUp;
    Offset mouseWorldClick;
    late PointerEvent lastPointerEvent;
    bool isMouseDown;
    BoxSelection boxSelectionWorld = BoxSelection.infinity();

    void handlePointerMove(Window window, PointerEvent event) {
        final curMousePosWorld = window.screenToWorld(event.position);
        mouseDelta = event.delta;
        mouseWorldDelta = mousePosWorld - curMousePosWorld;
        mousePosWorld = curMousePosWorld;

        if (event is PointerMoveEvent) {
            if (event.buttons == 2 || event.buttons == 4) {
                window.pan += mouseDelta;
            } else if (event.buttons == 1) {
                boxSelectionWorld.end = mousePosWorld;
            } else if (event.buttons == 1 && (event.buttons == 2 || event.buttons == 4)) {
                window.pan += mouseDelta;
                boxSelectionWorld.end = mousePosWorld;
            }
        } else if (event is PointerHoverEvent) {
            // ...
        }
    }

    void handlePointerUp(Window window, PointerEvent event) {
        //print(event);
        if (event is PointerUpEvent) {
            mouseUp = event.position;
            if(mouseUp == mouseDown) {// && event.buttons == 1) {
                mouseWorldClick = window.screenToWorld(mouseDown);
            }
            isMouseDown = false;            
        }
    }

    void handlePointerDown(Window window, PointerEvent event) {
        //print(event);
        if (event is PointerDownEvent) {
            mouseDown = event.position;
            isMouseDown = true;

            if(event.buttons == 1) {
                boxSelectionWorld = BoxSelection.fromStart(window.screenToWorld(event.position));
            }
        }
    }

    void handlePointerScroll(Window window, PointerScrollEvent event) {
        if (window.zoom >= window.zoomMin) {
            final zoomDelta = -event.scrollDelta.dy * _mouseSensitivity * window.zoom.abs();
            window.zoom += zoomDelta;
            window.zoom = window.zoom.clamp(window.zoomMin, window.zoomMax).toDouble();
            if (window.zoom != window.zoomMin && window.zoom != window.zoomMax) {
                final Offset panDelta = Offset(mousePosWorld.dx * zoomDelta, -mousePosWorld.dy * zoomDelta);
                window.pan -= panDelta;
            }
        }
        //print(window.zoom);
    }

    void handleKeyEvent(RawKeyEvent event) {
        //
        if (event.logicalKey == LogicalKeyboardKey.keyQ) {
            //
        } else {
            if (kReleaseMode) {
                //
            } else {
                //
            }
        }
    }
}
