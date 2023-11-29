import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icons.dart';
import 'input.dart';
import 'inspector.dart';
import 'painter.dart';
import 'window.dart';
import 'utils/utils.dart';

abstract class EditorElement {
    EditorElement({
        this.selected = false,
        this.position = const Offset(double.infinity, double.infinity),
    });

    Offset get center;
    void set center(Offset p);
    Offset position;
    bool selected;

    List<Node> getElementNodes() => [];
    void refreshGrid() {}
    void moveByDelta(Offset delta) {}
    bool? click(Window window, Offset mouseWorldClick) {}
    bool? boxSelect(BoxSelection selection) {}
    void render(Window window, Painter painter) {}
}

/// NodeFixator describes allowed movement of a node.
/// h — horisontal, v — vertical, t — turn
enum NodeFixator {
    hvt,
    hv,
    ht,
    vt,
    h,
    t,
    v,
    disabled,
}

class Node extends EditorElement {
    Node(this.position, {
        this.selected = false,
        this.force = const Offset(0, 0),
        this.torqueForce = 0,
        this.fixator = NodeFixator.disabled,
        this.radius = 10,
        this.fixatorRadius = 15,
        this.forceLabelOffset = 17,
        this.forceLabelFontSize = 12,
    });

    /// Data
    Offset position;
    Offset force;
    double torqueForce;
    NodeFixator fixator;

    /// UI
    bool selected;
    final double radius;
    final double fixatorRadius;
    final double forceLabelOffset;
    final double forceLabelFontSize;

    @override
    Offset operator +(Offset other) => Offset(position.dx + other.dx, position.dy + other.dy);
    Offset operator -(Offset other) => Offset(position.dx - other.dx, position.dy - other.dy);

    @override
    Offset get center => position;

    @override
    void set center(Offset p) => position = p;

    @override
    List<Node> getElementNodes() {
        return [this];
    }

    @override
    void refreshGrid() {}

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        selected = Rect.fromCircle(
            center: position,
            radius: radius,
        ).contains(mouseWorldClick);
        selected = isPointInCircle(mouseWorldClick, position, radius * (1 / window.zoom));
        return selected;
    }

    @override
    bool? boxSelect(BoxSelection selection) {
        selected = isPointInRect(center, selection.start, selection.end);
        return selected;
    }

    void drawForces(Window window, Painter painter) {
        if (force.dx != 0 || force.dy != 0) {
            painter.drawText(
                window: window,
                text: '[${force.dx.toStringAsFixed(2)}; ${force.dy.toStringAsFixed(2)}]',
                fontSize: forceLabelFontSize,
                textColor: Colors.black,
                bgColor: Colors.white,
                textOffset: window.worldToScreen(center) + Offset(0, -forceLabelOffset),
                outline: true,
                centerAlignX: true,
                centerAlignY: true,
            );
        }
    }

    @override
    void render(Window window, Painter painter) {
        if (fixator != NodeFixator.disabled) {
            painter.setPaint(color: selected ? Colors.orange.shade400 : Colors.grey.shade400);
            painter.drawRect(
                window,
                Rect.fromCircle(
                    center: window.worldToScreen(center),
                    radius: fixatorRadius,
                ),
            );
        }
        painter.setPaint(color: selected ? Colors.orange : Colors.grey);
        painter.drawCircle(window, window.worldToScreen(center), radius);
        drawForces(window, painter);
    }
}

enum BeamSection {
    arbitrary,
    rect,
    round,
}

class Beam extends EditorElement {
    Beam({
        required this.start,
        required this.end,
        this.force = const Offset(0, 0),
        this.width = 1,
        this.section = BeamSection.rect,
        this.sectionArea = 1,
        this.elasticity = 1,
        this.tension = 1,
    }) : assert(start != end);

    Node start;
    Node end;

    Offset force;
    double width;
    double sectionArea;
    double elasticity;
    double tension;
    BeamSection section;

    bool selected = false;

    late Offset a, b, c, d;
    final double centerCrossLength = 7;

    @override
    Offset get position => center;

    @override
    Offset get center => Offset(start.position.dx + end.position.dx, start.position.dy + end.position.dy) / 2;

    @override
    void set center(Offset value) {
        final offset = center - value;
        start.center -= offset;
        end.position -= offset;
    }

    double get length => Offset(start.position.dx - end.position.dx, start.position.dy - end.position.dy).distance;

    double get rotation { 
        final delta = Offset(end.position.dx - start.position.dx, end.position.dy - start.position.dy);
        return atan(delta.dy / delta.dx);
    }

    @override
    List<Node> getElementNodes() {
        return [start, end];
    }

    @override
    void moveByDelta(Offset delta) { 
        start.position -= delta;
        end.position -= delta;
    }

    @override
    void refreshGrid() {
        a = rotatePoint(start.position, Offset(start.position.dx, start.position.dy + width / 2), rotation);
        b = rotatePoint(start.position, Offset(start.position.dx, start.position.dy - width / 2), rotation);
        c = rotatePoint(end.position, Offset(end.position.dx, end.position.dy + width / 2), rotation);
        d = rotatePoint(end.position, Offset(end.position.dx, end.position.dy - width / 2), rotation);
    }

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        refreshGrid();

        selected = isPointInQuad(mouseWorldClick, a, b, c, d);
        return selected;
    }

    @override
    bool? boxSelect(BoxSelection selection) {
        selected = isPointInRect(center, selection.start, selection.end);
        return selected;
    }

    @override
    void render(Window window, Painter painter) {
        final color = selected ? Colors.orange : Colors.grey.shade700;
        painter.setPaint(color: color);
        painter.drawQuad(window, a, b, c, d);

        final screenCenter = window.worldToScreen(center);
        painter.setPaint(color: selected ? Colors.orange.shade700 : Colors.grey.shade900);
        for (final d in directions) {
            painter.drawLine(window, screenCenter + d * centerCrossLength, screenCenter - d * centerCrossLength);
        }
    }
}


abstract class EditorSelectionState {
    void processInput(Editor editor, Window window, Input input) {}
}

class EditorInitialSelectionState extends EditorSelectionState {
    EditorInitialSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {}
}

class EditorProcessSelectionState extends EditorSelectionState {
    EditorProcessSelectionState(Editor editor) {
        for(final e in editor.editorElements) {
            e.selected = false;
        }
    }
    @override
    void processInput(Editor editor, Window window, Input input) {
        if (!editor.selectedElements.isEmpty && (!input.isLMBDown)) {
            editor.changeSelectionState(EditorDoneSelectionState(editor));
        }

        editor.selectedElements = [];
        final start = input.boxSelectionWorld.start;
        final end = input.boxSelectionWorld.end;

        if (start != end) {
            final list = editor.bar.isBeamSelectionMode ? editor.beams : editor.nodes;
            for (final c in list) {
                final select = c.boxSelect(input.boxSelectionWorld);
                if (select != null) {
                    if (select) {
                        editor.selectedElements.add(c);
                    }        
                }
            }   
        } else {
            final list = editor.bar.isBeamSelectionMode ? editor.beams : editor.nodes;
            for (final c in list.reversed.toList()) {
                final click = c.click(window, input.lMBWorldClick);
                if (click != null && click) {
                    if (editor.selectedElements.isEmpty) {
                        editor.selectedElements.add(c);
                    } else {
                        c.selected = false;
                    }
                }
            }
        }
    }
}

class EditorDoneSelectionState extends EditorSelectionState {
    EditorDoneSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        final mouseInDragBox = Rect.fromCircle(
            center: editor.dragBox,
            radius: editor.dragBoxRadius * (1 / window.zoom),
        ).contains(input.mousePosWorld);

        if (input.isLMBDown && mouseInDragBox) {
            editor.changeSelectionState(EditorDragSelectionState(editor));
        } else if (input.isLMBDown && !mouseInDragBox) {
            editor.changeSelectionState(EditorProcessSelectionState(editor));
        }
    }
}

class EditorDragSelectionState extends EditorSelectionState {
    EditorDragSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        if (!input.isLMBDown) {
            editor.changeSelectionState(EditorDoneSelectionState(editor));
        } else {
            final Set<Node> nodes = {};
            for (final e in editor.selectedElements) {
                for (final node in e.getElementNodes()) {
                    nodes.add(node);
                }
            }
            for (final n in nodes) {
                n.position = n.position + (input.boxSelectionWorld.end - editor.dragBox);
            }

            editor.dragBox = input.boxSelectionWorld.end;
        }
    }
}

class Editor {
    Editor({
        this.nodes = const [],
        this.selectedElements = const [],
        this.beams = const [],
        this.dragBox = const Offset(double.infinity, double.infinity),
        this.dragBoxRadius = 10,
    }) {
        nodes = [
            Node(Offset(0, 0), fixator: NodeFixator.hvt),
            Node(Offset(1, 0)),
            Node(Offset(5, 0), fixator: NodeFixator.hvt),
            Node(Offset(9, 10)),
            Node(Offset(-5, 5)),
            Node(Offset(-9, 0)),
        ];
        nodes.add(Node(Offset(7, 7)));
        beams = [
            Beam(
                start: nodes[0],
                end: nodes[1],
                width: 1,
                section: BeamSection.round,
            ),
            Beam(
                start: nodes[2],
                end: nodes[3],
                width: 1,
                section: BeamSection.round,
            ),
            Beam(
                start: nodes[4],
                end: nodes[5],
                width: 1,
                section: BeamSection.round,
            ),
            Beam(
                start: nodes[3],
                end: nodes[5],
                width: 1,
                section: BeamSection.round,
            ),
        ];
        editorElements = List.from(nodes)..addAll(beams);
        bar = EditorBar(this);
        selectionState = EditorProcessSelectionState(this);
    }

    List<Node> nodes;
    List<Beam> beams;
    late List<EditorElement> editorElements;
    List<EditorElement> selectedElements;


    Offset dragBox;
    double dragBoxRadius;

    Grid grid = Grid();

    late EditorSelectionState selectionState;
    late EditorBar bar;
    Color boxSelectionColor = Color.fromRGBO(13, 88, 166, 192);

    void resetSelectionState() {
        selectionState = EditorProcessSelectionState(this);
    }

    void changeSelectionState(EditorSelectionState state) {
        selectionState = state;
    }

    /// Input
    void processInput(Window window, Input input) {
        selectionState.processInput(this, window, input);
    }

    /// Input Grid
    void drawBoxSelection(Window window, Painter painter, Input input) {
        final selection = input.boxSelectionWorld;
        if (input.isLMBDown && selection.start != selection.end) {
            painter.setPaint(color: boxSelectionColor, width: 1);
            painter.drawCircle(window, window.worldToScreen(selection.start), 10);
            painter.drawCircle(window, window.worldToScreen(selection.end), 10);
            painter.drawRect(
                window,
                Rect.fromPoints(
                    window.worldToScreen(selection.start), 
                    window.worldToScreen(selection.end),
                )
            );
        }
    }

    /// Rendering
    void drawBeams(Window window, Painter painter) {
        for (final c in beams) {
            c.refreshGrid();
            c.render(window, painter);
        }
    }

    void drawNodes(Window window, Painter painter) {
        for (final n in nodes) {
            n.render(window, painter);
        }   
    }

    void drawDragBox(Window window, Painter painter) {
        Offset selectedCentersSum = Offset(0, 0);
        final int n = selectedElements.length;
        if (n > 0) {
            for (int i = 0; i < n; i++) {
                selectedCentersSum += selectedElements[i].center; 
            }
            dragBox = selectedCentersSum / n.toDouble();
            painter.setPaint(color: Color.fromRGBO(0, 0, 255, 192), width: 1);
            painter.drawRect(
                window,
                Rect.fromCenter(
                    center: window.worldToScreen(dragBox),
                    width: dragBoxRadius,
                    height: dragBoxRadius * 4,
                ),
            );
            painter.setPaint(color: Color.fromRGBO(255, 0, 0, 192), width: 1);
            painter.drawRect(
                window,
                Rect.fromCenter(
                    center: window.worldToScreen(dragBox),
                    width: dragBoxRadius * 4,
                    height: dragBoxRadius,
                ),
            );
        }
    }

    void render(Window window, Painter painter, Input input) {
        grid.render(window, painter);
        drawBeams(window, painter);
        drawNodes(window, painter);
        drawDragBox(window, painter);
        drawBoxSelection(window, painter, input);
    }
}

class Grid {
    void draw(Window window, Painter painter) {
        final double depth = 1;
        final double gridSteps = 5;
        final double step = 5 * depth;
        final List<Offset> directions = [
            Offset(0, step),
            Offset(step, 0),
        ];
        final double border = 20;
        final double depthStep = window.zoom;
        final double borderHeight = window.height - 1.1 * border;
        final double borderWidth = window.width - 1.5 * border;

        final centerStep = step * step * (window.zoom); //step * step * zoom;

        /*
        print("Center step $centerStep");
        print(width % centerStep);
        print(width - width % centerStep);
        print(pan.dx);
        print(pan.dx % (width - width % centerStep));
        */

        //Offset screenPan = Offset(window.pan.dx % (window.width - window.width % centerStep),
        //                          window.pan.dy % (window.height - window.height % centerStep)) - window.center * window.zoom;

        Offset screenPan = -window.size + (window.size % centerStep) + window.pan % centerStep;

        //painter.drawCircle(window, screenPan, 200);
        //print(window.zoom);
        //print(depth);

        for (final direction in directions) {
            double count = 0;
            for (Offset i = screenPan; count < window.width / window.zoom; i += direction * window.zoom) {
                count % gridSteps == 0 ? painter.setPaint(color: Colors.black, width: 1) :
                                    painter.setPaint(color: Colors.grey.shade400, width: 1);
                painter.drawLine(window, Offset(i.dx, 0), Offset(i.dx, window.height));
                painter.drawLine(window, Offset(0, i.dy), Offset(window.width, i.dy));
                count++;
            }
        }

        painter.setPaint(color: Colors.blue.shade800, width: 3);
        painter.drawLine(
            window,
            Offset(window.pan.dx, 0),
            Offset(window.pan.dx, window.height),
        );

        painter.setPaint(color: Colors.red, width: 3);
        painter.drawLine(
            window,
            Offset(0, window.pan.dy),
            Offset(window.width, window.pan.dy),
        );

        for (final direction in directions) {
            final bool isVertical = (direction.dx == 0);
            bool clamped = false;
            double count = 0;
            for (Offset i = screenPan; count < window.width / window.zoom; i += direction * window.zoom * step * depth) {
                //painter.drawCircle(window, i, 30);
                final Offset textOffset = isVertical ? Offset(window.pan.dx.clamp(border, borderWidth), i.dy) :
                                                       Offset(i.dx, window.pan.dy.clamp(border, borderHeight));
                clamped = (textOffset.dx == border || textOffset.dy == border ||
                           textOffset.dx == borderWidth || textOffset.dy == borderHeight);
                final textValue = window.screenToWorld(i);
                final String text = (isVertical ? textValue.dy.toStringAsFixed(0) : textValue.dx.toStringAsFixed(0));
                if (text == "0" || text == "-0") continue;
                painter.drawText(
                    window: window,
                    text: text,
                    fontSize: 18,
                    textColor: clamped ? Colors.grey.shade600 : Colors.black,
                    bgColor: clamped ? Color.fromRGBO(0, 0, 0, 0.15) : Color.fromRGBO(255, 255, 255, 0),
                    outline: !clamped,
                    textOffset: textOffset,
                    centerAlignX: true,
                    centerAlignY: true,
                );
                count++;
            }
        }
    }

    void render(Window window, Painter painter) {
        draw(window, painter);
    }
}

class EditorBar extends StatefulWidget {
    EditorBar(Editor this.editor);

    Editor editor;
    List<bool> selectionMode = [true, false];
    static bool _showElementsData = false;

    bool get isBeamSelectionMode => selectionMode[0];
    bool get isNodeSelectionMode => selectionMode[1];

    bool get isDataHide => _showElementsData;
    void set isDataHide(bool value) => _showElementsData = value;

    void unselectAllElements() {
        editor.resetSelectionState();
    }

    @override
    State<EditorBar> createState() => _EditorBarState();
}

class _EditorBarState extends State<EditorBar> {
    @override
    Widget build(BuildContext context) {
        return Container(
            child: Row(
                children: [
                    ToggleButtons(
                        onPressed: (int index) {
                            setState(() {
                                widget.unselectAllElements();
                                for (int i = 0; i < widget.selectionMode.length; i++) {
                                    widget.selectionMode[i] = i == index;
                                }
                            });
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        selectedBorderColor: Colors.blue[700],
                        selectedColor: Colors.white,
                        disabledBorderColor: Color.fromRGBO(255, 255, 255, 1.0),
                        disabledColor: Color.fromRGBO(255, 255, 255, 1.0),
                        fillColor: Colors.blue[200],
                        color: Colors.blue[400],
                        isSelected: widget.selectionMode,
                        children: selectionModeIcons,
                    ),
                    /*
                    ToggleButtons(
                        onPressed: (int index) {
                            setState(() {
                                widget.unselectAllElements();
                                for (int i = 0; i < widget.selectionMode.length; i++) {
                                    widget.selectionMode[i] = i == index;
                                }
                            });
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        selectedBorderColor: Colors.blue[700],
                        selectedColor: Colors.white,
                        disabledBorderColor: Color.fromRGBO(255, 255, 255, 1.0),
                        disabledColor: Color.fromRGBO(255, 255, 255, 1.0),
                        fillColor: Colors.blue[200],
                        color: Colors.blue[400],
                        isSelected: widget.selectionMode,
                        children: ,
                    ),
                    */
                ],
            ),
        );
    }
}

class BoxSelection {
    BoxSelection(this.start, this.end);
    BoxSelection.fromStart(Offset start) : start = start, end = start;
    BoxSelection.infinity()
        : start = Offset(double.infinity, double.infinity),
          end = Offset(double.infinity, double.infinity);

    Offset start;
    Offset end;

    BoxSelection toWorld(Window window, Offset worldPoint) =>
        BoxSelection(window.screenToWorld(start), window.screenToWorld(end));

    @override
    String toString() {
        return "BoxSelection($start, $end)";
    }
}
