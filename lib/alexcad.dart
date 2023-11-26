library alexcad;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/utils.dart';
import 'app_icons.dart';

abstract class EditorElement {
    Offset get center;
    void set center(Offset p);
    Offset position;
    bool selected;

    EditorElement({this.selected = false, this.position = const Offset(double.infinity, double.infinity)});

    List<Node> getElementNodes() => [];
    void refreshUI() {}
    void moveByDelta(Offset delta) {}
    bool? click(Window window, Offset mouseWorldClick) {}
    bool? boxSelect(BoxSelection selection) {}
    void render(Window window, Painter painter) {}
}

class Node extends EditorElement {
    Node(this.position, {this.selected = false});

    Offset position;
    bool selected;

    final double radius = 10;

    Offset get center => position;

    @override
    Offset operator +(Offset other) => Offset(position.dx + other.dx, position.dy + other.dy);
    Offset operator -(Offset other) => Offset(position.dx - other.dx, position.dy - other.dy);

    @override
    void set center(Offset p) => position = p;

    @override
    List<Node> getElementNodes() {
        return [this];
    }

    @override
    void refreshUI() {}

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        selected = Rect.fromCircle(
            center: position,
            radius: radius,
        ).contains(mouseWorldClick);
        selected = isPointInCircle(mouseWorldClick, position, radius * (1 / window.zoom));
        print(selected);
        return selected;
    }

    @override
    bool? boxSelect(BoxSelection selection) {
        selected = isPointInRect(center, selection.start, selection.end);
        return selected;
    }

    @override
    void render(Window window, Painter painter) {
        painter.setPaint(color: selected ? Colors.orange : Colors.grey);
        painter.drawCircle(window, window.worldToScreen(center), radius);
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
        this.width = 1,
        this.section = BeamSection.rect,
        this.sectionArea = 1,
        this.elasticity = 1,
        this.tension = 1,
    }) : assert(start != end);

    Node start;
    Node end;
    BeamSection section;
    double width;
    double sectionArea;
    double elasticity;
    double tension;
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
    void refreshUI() {
        a = rotatePoint(start.position, Offset(start.position.dx, start.position.dy + width / 2), rotation);
        b = rotatePoint(start.position, Offset(start.position.dx, start.position.dy - width / 2), rotation);
        c = rotatePoint(end.position, Offset(end.position.dx, end.position.dy + width / 2), rotation);
        d = rotatePoint(end.position, Offset(end.position.dx, end.position.dy - width / 2), rotation);
    }

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        refreshUI();

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

class EditorBar extends StatefulWidget {
    List<bool> selectionMode = [true, false];

    bool get isBeamSelectionMode => selectionMode[0];
    bool get isNodeSelectionMode => selectionMode[1];

    @override
    State<EditorBar> createState() => _EditorBarState();
}

class _EditorBarState extends State<EditorBar> {
    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            child: ToggleButtons(
                onPressed: (int index) {
                    setState(() {
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
        );
    }
}

class Inspector extends StatefulWidget {
    const Inspector(this.selectedElements, {
        super.key,
        this.width = 400,
        this.height = 1080,
        this.color = const Color.fromRGBO(179, 196, 255, 1),
        this.title = "Inspector",
        this.child,
    });

    final List<dynamic> selectedElements;
    final double width;
    final double height;
    final Color color;
    final String title;
    final Widget? child;

    @override
    State<Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
    final xFieldController = TextEditingController();
    final yFieldController = TextEditingController();

    final sectionValues = BeamSection.values.map((e) => DropdownMenuItem(
        child: Text(e.name),
        value: e.name,
    )).toList();

    bool isSelectedElementsEmpty() {
        return widget.selectedElements.isEmpty;   
    }

    String getBeamSection() {
        if (widget.selectedElements[0] is Beam) {
            return widget.selectedElements[0].section.toString();
        } else {
            return "NOT A BEAM";
        }
    }

    void setBeamSection(String? s) {
        if (s != null && widget.selectedElements[0] is Beam) {
            widget.selectedElements[0].section = s;
        }
    }

    @override
    void dispose() {
        xFieldController.dispose();
        yFieldController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        String selected = widget.selectedElements.toString();
        return Container(
            width: widget.width,
            height: widget.height,
            color: widget.color,
            /*
            child: Column(
                children: [
                    Text("${widget.title}"),
                    isSelectedElementsEmpty() ? Row() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "Position",
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    controller: TextEditingController(text: widget.selectedElements[0].center.dx.toString()),
                                    decoration: InputDecoration(labelText: "X"),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp('[0-9\.]')),
                                    ],
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    controller: TextEditingController(text: widget.selectedElements[0].center.dy.toString()),
                                    decoration: InputDecoration(labelText: "Y"),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp('[0-9\.]')),
                                    ],
                                ),
                            ),
                            TextButton(
                                style: TextButton.styleFrom(
                                    primary: Colors.blue,
                                    onSurface: Colors.red,
                                ),
                                onPressed: () {
                                    //TODO!!
                                },
                                child: Text("Tap"),
                            ),
                            /*
                            Container(
                                width: 300.0,
                                child: DropdownButtonHideUnderline(
                                    child: ButtonTheme(
                                        alignedDropdown: true,
                                        child: DropdownButton(
                                            value: getBeamSection(),
                                            items: sectionValues,
                                            onChanged: setBeamSection,
                                            style: const TextStyle(color: Colors.blue),
                                        ),
                                    ),
                                ),
                            ),
                            */
                        ],
                    ),
                    isSelectedElementsEmpty() ? Row() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "Section area",
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    controller: TextEditingController(text: widget.selectedElements[0].sectionArea.toString()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp('[0-9\.]')),
                                    ],
                                ),
                            ),
                        ]
                    ),
                    isSelectedElementsEmpty() ? Row() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "|Elasticity|",
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    controller: TextEditingController(text: widget.selectedElements[0].elasticity.toString()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp('[0-9\.]')),
                                    ],
                                ),
                            ),
                        ]
                    ),
                    isSelectedElementsEmpty() ? Row() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "Tension [σ]",
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    controller: TextEditingController(text: widget.selectedElements[0].tension.toString()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp('[0-9\.]')),
                                    ],
                                ),
                            ),
                        ]
                    ),
                    isSelectedElementsEmpty() ? Row() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "Section",
                                ),
                            ),
                            Flexible(
                                child: Text(
                                    getBeamSection(),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
            */
        );
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
    EditorProcessSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        if (!editor.selectedElements.isEmpty && !input.isMouseDown) {
            editor.changeSelectionState(EditorDoneSelectionState(editor));
        }

        editor.selectedElements = [];
        final start = input.boxSelectionWorld.start;
        final end = input.boxSelectionWorld.end;

        if (start != end) {
            final list = editor.bar.isBeamSelectionMode ? editor.constructions : editor.nodes;
            for (final c in list) {
                final select = c.boxSelect(input.boxSelectionWorld);
                if (select != null) {
                    if (select) {
                        editor.selectedElements.add(c);
                    }        
                }
            }   
        } else {
            final list = editor.bar.isBeamSelectionMode ? editor.constructions : editor.nodes;
            for (final c in list.reversed.toList()) {
                final click = c.click(window, input.mouseWorldClick);
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

        if (input.isMouseDown && mouseInDragBox) {
            editor.changeSelectionState(EditorDragSelectionState(editor));
        } else if (input.isMouseDown && !mouseInDragBox) {
            editor.changeSelectionState(EditorProcessSelectionState(editor));
        }
    }
}

class EditorDragSelectionState extends EditorSelectionState {
    EditorDragSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        if (!input.isMouseDown) {
            editor.changeSelectionState(EditorDoneSelectionState(editor));
        } else {
            final Set<Node> nodes = {};
            for (final e in editor.selectedElements) {
                for (final node in e.getElementNodes()) {
                    nodes.add(node);
                }
                print(e.toString()
                    );
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
        this.constructions = const [],
        this.dragBox = const Offset(double.infinity, double.infinity),
        this.dragBoxRadius = 10,
    }) {
        nodes = [
            Node(Offset(0, 0)),
            Node(Offset(1, 0)),
            Node(Offset(5, 0)),
            Node(Offset(9, 10)),
            Node(Offset(-5, 5)),
            Node(Offset(-9, 0)),
        ];
        nodes.add(Node(Offset(7, 7)));
        constructions = [
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
        selectionState = EditorProcessSelectionState(this);
    }

    List<Node> nodes;
    List<Beam> constructions;
    List<EditorElement> selectedElements;


    Offset dragBox;
    double dragBoxRadius;

    EditorBar bar = EditorBar();

    late EditorSelectionState selectionState;
    Color boxSelectionColor = Color.fromRGBO(13, 88, 166, 192);

    void changeSelectionState(EditorSelectionState state) {
        selectionState = state;
        print(selectionState);
    }

    /// Input
    void processInput(Window window, Input input) {
        selectionState.processInput(this, window, input);
    }

    /// Input UI
    void drawBoxSelection(Window window, Painter painter, Input input) {
        final selection = input.boxSelectionWorld;
        if (input.isMouseDown && selection.start != selection.end) {
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
    void drawConstructions(Window window, Painter painter) {
        for (final c in constructions) {
            c.refreshUI();
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
        drawConstructions(window, painter);
        drawNodes(window, painter);
        drawDragBox(window, painter);
        drawBoxSelection(window, painter, input);
    }
}

class UI {
    void drawGrid(Window window, Painter painter) {
        final double depthStep = window.zoom;
        final double depth = 1;
        final double gridSteps = 5;
        final double step = 5 * depth;
        final List<Offset> directions = [
            Offset(0, step),
            Offset(step, 0),
        ];
        const double border = 20;
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
        drawGrid(window, painter);
    }
}

class Window {
    late Canvas canvas;
    late Size _size;

    double zoom = 20;
    Offset pan = Offset(500, 500);
    
    final double _zoomMin = 5.00;
    final double _zoomMax = 40.0;

    double get width => _size.width;
    double get height => _size.height;
    double get aspectRatio => width / height;
    Offset get size => Offset(width, height);
    Offset get center => size / 2;

    void init(Canvas canvas, Size size) {
        this.canvas = canvas;
        this._size = size;
    }

    Offset worldToScreen(Offset worldPoint) =>
        Offset(worldPoint.dx * zoom + pan.dx, -worldPoint.dy * zoom + pan.dy);
    Offset screenToWorld(Offset screenPoint) =>
        Offset((screenPoint.dx - pan.dx) / zoom, -(screenPoint.dy - pan.dy) / zoom);
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
        if (window.zoom >= window._zoomMin) {
            final zoomDelta = -event.scrollDelta.dy * _mouseSensitivity * window.zoom.abs();
            window.zoom += zoomDelta;
            window.zoom = window.zoom.clamp(window._zoomMin, window._zoomMax);
            if (window.zoom != window._zoomMin && window.zoom != window._zoomMax) {
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
