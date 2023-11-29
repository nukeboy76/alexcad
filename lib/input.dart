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
        this.lMBWorldClick = const Offset(0, 0),
        this.rMBWorldClick = const Offset(0, 0),
        this.lMBDown = const Offset(0, 0),
        this.lMBUp = const Offset(0, 0),
        this.rMBDown = const Offset(0, 0),
        this.rMBUp = const Offset(0, 0),
        this.isLMBDown = false,
        this.isRMBDown = false,
    });

    final double _mouseSensitivity = 0.001;

    Offset mousePosWorld;
    Offset mouseWorldDelta;
    Offset mouseDelta;
    Offset lMBWorldClick;
    Offset rMBWorldClick;
    Offset lMBDown;
    Offset lMBUp;
    Offset rMBDown;
    Offset rMBUp;
    bool isLMBDown;
    bool isRMBDown;
    late PointerEvent lastPointerEvent;
    BoxSelection boxSelectionWorld = BoxSelection.infinity();

    void handlePointerMove(Window window, PointerEvent event) {
        final curMousePosWorld = window.screenToWorld(event.position);
        mouseDelta = event.delta;
        mouseWorldDelta = mousePosWorld - curMousePosWorld;
        mousePosWorld = curMousePosWorld;

        if (event is PointerMoveEvent) {
            if ([2, 4].contains(event.buttons)) {
                window.pan += mouseDelta;
            } else if (event.buttons == 1) {
                boxSelectionWorld.end = mousePosWorld;
            } else if (event.buttons == 1 && [2, 4].contains(event.buttons)) {
                window.pan += mouseDelta;
                boxSelectionWorld.end = mousePosWorld;
            }
        } /*else if (event is PointerHoverEvent) {
            // ...
        }*/
    }

    void handlePointerUp(Window window, PointerEvent event) {
        isLMBDown = false;
        isRMBDown = false;
        if (event.buttons == 1) {
            lMBUp = event.position;
            if (lMBUp == lMBDown) {
                lMBWorldClick = window.screenToWorld(lMBDown);
            }
        } else if ([2, 4].contains(event.buttons)) {
            rMBUp = event.position;
            if (rMBUp == rMBDown) {
                rMBWorldClick = window.screenToWorld(rMBDown);
            }
        }
    }

    void handlePointerDown(Window window, PointerEvent event) {
        if (event.buttons == 1) {
            lMBDown = event.position;
            boxSelectionWorld = BoxSelection.fromStart(window.screenToWorld(lMBDown));
            isLMBDown = true;
        } else if ([2, 4].contains(event.buttons)) {
            rMBDown = event.position;
            boxSelectionWorld = BoxSelection.fromStart(window.screenToWorld(rMBDown));
            isRMBDown = true;
        }
        /*
        print('isLMBDown');
        print(isLMBDown);
        print('isRMBDown');
        print(isRMBDown);
        */
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
