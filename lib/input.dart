import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor.dart';
import 'inspector.dart';
import 'painter.dart';
import 'window.dart';
import 'utils/utils.dart';


class Input {
    Input({
        this.mousePosWorld = Offset.infinite,
        this.mouseWorldDelta = Offset.infinite,
        this.mouseDelta = Offset.infinite,
        this.lMBWorldClick = Offset.infinite,
        this.rMBWorldClick = Offset.infinite,
        this.lMBDown = Offset.infinite,
        this.lMBUp = Offset.infinite,
        this.rMBDown = Offset.infinite,
        this.rMBUp = Offset.infinite,
        this.isLMBDown = false,
        this.isRMBDown = false,
        this.barHeight = 60,
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

    double barHeight;

    List<LogicalKeyboardKey> keyboardEventBuffer = [];

    void handlePointerMove(Window window, PointerEvent event) {
        final curMousePosWorld = window.screenToWorld(event.position - Offset(0, barHeight));
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

    /// TODO: Flutter can't detect current mouse up button, always return event.buttons.
    /// Need to finde the way how to differ it.
    void handlePointerUp(Window window, PointerEvent event) {
        isLMBDown = false;
        isRMBDown = false;
        lMBUp = event.position - Offset(0, barHeight);;
        rMBUp = event.position - Offset(0, barHeight);;

        if (lMBUp == lMBDown) {
            lMBWorldClick = window.screenToWorld(lMBDown);
        }

        if (rMBUp == rMBDown) {
            rMBWorldClick = window.screenToWorld(rMBDown);
        }

        /*
        if (event.buttons == 1) {
            lMBUp = event.position;
            if (lMBUp == lMBDown) {
                lMBWorldClick = window.screenToWorld(lMBDown);
            }
            isLMBDown = false;
        } else if ([2, 4].contains(event.buttons)) {
            rMBUp = event.position;
            if (rMBUp == rMBDown) {
                rMBWorldClick = window.screenToWorld(rMBDown);
            }
            isRMBDown = false;
        }
        */
    }

    void handlePointerDown(Window window, PointerEvent event) {
        if (event.buttons == 1) {
            lMBDown = event.position - Offset(0, barHeight);
            boxSelectionWorld = BoxSelection.fromStart(window.screenToWorld(lMBDown));
            isLMBDown = true;
        } else if ([2, 4].contains(event.buttons)) {
            rMBDown = event.position - Offset(0, barHeight);
            boxSelectionWorld = BoxSelection.fromStart(window.screenToWorld(rMBDown));
            isRMBDown = true;
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
    }

    void handleKeyEvent(RawKeyEvent event) {
        if (keyboardEventBuffer.length > 8) keyboardEventBuffer..removeAt(0);
        keyboardEventBuffer.add(event.logicalKey);
    }
}


class BoxSelection {
    BoxSelection(this.start, this.end);
    BoxSelection.fromStart(Offset start) : start = start, end = start;
    BoxSelection.infinity()
        : start = Offset.infinite,
          end = Offset.infinite;

    Offset start;
    Offset end;

    BoxSelection toWorld(Window window, Offset worldPoint) =>
        BoxSelection(window.screenToWorld(start), window.screenToWorld(end));

    @override
    String toString() {
        return "BoxSelection($start, $end)";
    }
}
