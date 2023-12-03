import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cad_colors.dart';
import 'cad_icons.dart';
import 'input.dart';
import 'inspector.dart';
import 'painter.dart';
import 'types.dart';
import 'utils/utils.dart';
import 'window.dart';


const List<Widget> selectionModeIcons = <Widget>[
    Icon(
       CadIcons.polygonEdges,
       size: 32,
    ),
    Icon(
       CadIcons.polygonVerticies,
       size: 32,
    ),
];


abstract class EditorView {
    EditorView({
        this.editorElement,
    });

    final editorElement;

    void render(Window window, Painter painter) {}
    void renderUI(Window window, Painter painter) {}
    bool? click(Window window, Offset mouseWorldClick) {}
    bool? boxSelect(BoxSelection selection) {}
    void refreshCanvasData() {}
}


abstract class EditorElement {
    EditorElement({
        this.selected = false,
    });

    Offset get center;
    Offset get position;
    void set position(Offset p);
    bool selected;

    late InspectorView inspectorView;
    late EditorView editorView;

    List<Node> getElementNodes() => [];
    void moveByDelta(Offset delta) {}
    void render(Window window, Painter painter) {}
}


class Node extends EditorElement {
    Node(double x, double y, {
        this.selected = false,
        this.force = const Offset(0, 0),
        this.torqueForce = 0,
        this.fixator = NodeFixator.disabled,
    }) {
        this._position = Offset(x, y);
        this.editorView = NodeEditorView(this);
        this.inspectorView = NodeInspectorView(this);
    }

    /// Data
    Offset _position = Offset.infinite;
    Offset force;
    double torqueForce;
    NodeFixator fixator;

    bool selected;

    late EditorView editorView;
    late InspectorView inspectorView;

    @override
    Offset operator +(Offset other) => Offset(_position.dx + other.dx, _position.dy + other.dy);
    Offset operator -(Offset other) => Offset(_position.dx - other.dx, _position.dy - other.dy);

    @override
    Offset get center => _position;

    @override
    Offset get position => _position;

    @override
    void set position(Offset p) => _position = p;

    @override
    List<Node> getElementNodes() {
        return [this];
    }
}


class NodeEditorView extends EditorView {
    NodeEditorView(this.editorElement, {
        this.radius = 10,
        this.fixatorRadius = 15,
        this.forceLabelOffset = 17,
        this.forceLabelFontSize = 12,
    });

    final editorElement;

    final double radius;
    final double fixatorRadius;
    final double forceLabelOffset;
    final double forceLabelFontSize;

    @override
    void render(Window window, Painter painter) {
        if (editorElement.fixator != NodeFixator.disabled) {
            painter.setPaint(color: editorElement.selected ? cianColor.darker(0.5) : Colors.grey.shade400);
            painter.drawRect(
                window,
                Rect.fromCircle(
                    center: window.worldToScreen(editorElement.center),
                    radius: fixatorRadius,
                ),
            );
        }
        painter.setPaint(color: editorElement.selected ? cianColor.darker(0.3) : Colors.grey);
        painter.drawCircle(window, window.worldToScreen(editorElement.center), radius);
    }

    @override
    void renderUI(Window window, Painter painter) {
        if (editorElement.force.dx != 0 || editorElement.force.dy != 0) {
            painter.drawText(
                window: window,
                text: '[${editorElement.force.dx.toStringAsFixed(2)}; ${editorElement.force.dy.toStringAsFixed(2)}]',
                fontSize: forceLabelFontSize,
                textColor: Colors.black,
                bgColor: Color(0x00ffffff),
                textOffset: window.worldToScreen(editorElement.center) + Offset(0, -forceLabelOffset),
                outline: true,
                outlineSize: 1.25,
                centerAlignX: true,
                centerAlignY: true,
            );
        }
    }

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        editorElement.selected = Rect.fromCircle(
            center: editorElement.position,
            radius: radius,
        ).contains(mouseWorldClick);
        editorElement.selected = isPointInCircle(mouseWorldClick, editorElement.position, radius * (1 / window.zoom));
        return editorElement.selected;
    }

    @override
    bool? boxSelect(BoxSelection selection) {
        editorElement.selected = isPointInRect(editorElement.center, selection.start, selection.end);
        return editorElement.selected;
    }

    @override
    void refreshCanvasData() {}
}


class Beam extends EditorElement {
    Beam({
        required this.start,
        required this.end,
        this.force = const Offset(0, 0),
        this.width = 1,
        this.sectionArea = 1,
        this.elasticity = 1,
        this.tension = 1,
        this.section = BeamSection.rect,
        this.selected = false,
    }) : assert(start != end) {
        this.inspectorView = BeamInspectorView(this);
        this.editorView = BeamEditorView(this);
    }

    Node start;
    Node end;

    Offset force;
    double width;
    double sectionArea;
    double elasticity;
    double tension;
    BeamSection section;

    bool selected;

    late EditorView editorView;
    late InspectorView inspectorView;

    @override
    Offset get center => Offset(start.position.dx + end.position.dx, start.position.dy + end.position.dy) / 2;

    @override
    Offset get position => center;

    @override
    void set position(Offset value) {
        final offset = center - value;
        start.position -= offset;
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
}


class BeamEditorView extends EditorView {
    BeamEditorView(this.editorElement, {
        this.centerCrossLength = 7,
        this.forceLabelOffset = 17,
        this.forceLabelFontSize = 12,
    });

    final editorElement;

    late Offset a, b, c, d;
    final double centerCrossLength;
    final double forceLabelOffset;
    final double forceLabelFontSize;

    @override
    void render(Window window, Painter painter) {
        final color = editorElement.selected ? cianColor.darker(0.3) : Colors.grey.shade700;
        painter.setPaint(color: color);
        painter.drawQuad(window, a, b, c, d);
    }

    void drawForceArrows(Window window, Painter painter) {
        painter.setPaint(color: cianColor.color);

        //const double triangleStep = 10;
        //int totalTriangles = ((editorElement.start.position - editorElement.end.position) / triangleStep).toInt();
        //totalTriangles = totalTriangles < 1 ? 1 : totalTriangles; 

        const lerpFactor = 0.1;
        var aArrow = a;
        var bArrow = b;

        if (editorElement.force.dx > 0) {
            final cStart = lerpOffset(editorElement.start.position, editorElement.end.position, lerpFactor);
            for (
                Offset cArrow = cStart;
                (cArrow - editorElement.end.position).distance > 0.01;
            ) {
                painter.drawTriangle(
                    window,
                    window.worldToScreen(aArrow),
                    window.worldToScreen(bArrow),
                    window.worldToScreen(cArrow),
                );

                aArrow = lerpOffset(aArrow, c, lerpFactor);
                bArrow = lerpOffset(bArrow, d, lerpFactor);
                cArrow = lerpOffset(cArrow, editorElement.end.position, lerpFactor);
            }
        }
        /*
        if (editorElement.force.dx > 0) {
            final cStart = lerpOffset(editorElement.start.position, editorElement.end.position, lerpFactor);
            for (
                Offset cArrow = cStart;
                (cArrow - editorElement.end.position).distance > 0.01;
            ) {
                painter.drawTriangle(
                    window,
                    window.worldToScreen(aArrow),
                    window.worldToScreen(bArrow),
                    window.worldToScreen(cArrow),
                );

                aArrow = lerpOffset(aArrow, c, lerpFactor);
                bArrow = lerpOffset(bArrow, d, lerpFactor);
                cArrow = lerpOffset(cArrow, editorElement.end.position, lerpFactor);
            }
        }*/ else if (editorElement.force.dx < 0) {

        }
    }

    void drawBeamCenter(Window window, Painter painter) {
        final beamCenterOnScreen = window.worldToScreen(editorElement.center);
        painter.setPaint(color: editorElement.selected ? cianColor.darker(0.5) : Colors.grey.shade900);
        for (final d in directions) {
            painter.drawLine(window, beamCenterOnScreen + d * centerCrossLength, beamCenterOnScreen - d * centerCrossLength);
        }
    }

    @override
    void renderUI(Window window, Painter painter) {
        drawForceArrows(window, painter);
        if (editorElement.force.dx != 0 || editorElement.force.dy != 0) {
            painter.drawText(
                window: window,
                text: '[${editorElement.force.dx.toStringAsFixed(2)}; ${editorElement.force.dy.toStringAsFixed(2)}]',
                fontSize: forceLabelFontSize,
                textColor: Colors.black,
                bgColor: Color(0x00ffffff),
                textOffset: window.worldToScreen(editorElement.center) + Offset(0, -forceLabelOffset),
                outline: true,
                outlineSize: 1.25,
                centerAlignX: true,
                centerAlignY: true,
            );
        }

        drawBeamCenter(window, painter);
    }

    @override
    bool? click(Window window, Offset mouseWorldClick) {
        refreshCanvasData();
        editorElement.selected = isPointInQuad(mouseWorldClick, a, b, c, d);
        return editorElement.selected;
    }

    @override
    bool? boxSelect(BoxSelection selection) {
        editorElement.selected = isPointInRect(editorElement.start.center, selection.start, selection.end) &&
                                 isPointInRect(editorElement.end.center, selection.start, selection.end);
        return editorElement.selected;
    }

    @override
    void refreshCanvasData() {
        a = rotatePoint(
            editorElement.start.position,
            Offset(editorElement.start.position.dx, editorElement.start.position.dy + editorElement.width / 2),
            editorElement.rotation,
        );
        b = rotatePoint(
            editorElement.start.position,
            Offset(editorElement.start.position.dx, editorElement.start.position.dy - editorElement.width / 2),
            editorElement.rotation,
        );
        c = rotatePoint(
            editorElement.end.position,
            Offset(editorElement.end.position.dx, editorElement.end.position.dy + editorElement.width / 2),
            editorElement.rotation,
        );
        d = rotatePoint(
            editorElement.end.position,
            Offset(editorElement.end.position.dx, editorElement.end.position.dy - editorElement.width / 2),
            editorElement.rotation,
        );
    }
}


abstract class EditorSelectionState {
    void processInput(Editor editor, Window window, Input input) {}
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class EditorInitialSelectionState extends EditorSelectionState {
    EditorInitialSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {}

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class EditorProcessSelectionState extends EditorSelectionState {
    EditorProcessSelectionState(Editor editor) {
        for(final e in editor.elements) {
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
        final list = editor.bar.isBeamSelectionMode ? editor.beams : editor.nodes;

        if (start != end) {
            for (final c in list) {
                final select = c.editorView.boxSelect(input.boxSelectionWorld);
                if (select != null) {
                    if (select) {
                        editor.selectedElements.add(c);
                    }        
                }
            }   
        } else {
            for (final c in list.reversed.toList()) {
                final click = c.editorView.click(window, input.lMBWorldClick);
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

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {
        const double selectionPointRadius = 7;
        final selection = input.boxSelectionWorld;
        if (input.isLMBDown && selection.start != selection.end) {
            painter.setPaint(color: cianColor.darker(0.25).withOpacity(0.2), width: 1);
            painter.drawCircle(window, window.worldToScreen(selection.start), selectionPointRadius);
            painter.drawCircle(window, window.worldToScreen(selection.end), selectionPointRadius);

            painter.drawRect(
                window,
                Rect.fromPoints(
                    window.worldToScreen(selection.start), 
                    window.worldToScreen(selection.end),
                )
            );
        }
    }
}


class EditorDoneSelectionState extends EditorSelectionState {
    EditorDoneSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        final mouseInDragBox = Rect.fromCircle(
            center: editor.dragBoxPosition,
            radius: editor.dragBoxRadius,
        ).contains(input.mousePosWorld);

        if (input.isLMBDown && mouseInDragBox) {
            editor.changeSelectionState(EditorDragSelectionState(editor));
        } else if (input.isLMBDown && !mouseInDragBox) {
            editor.changeSelectionState(EditorProcessSelectionState(editor));
        }
    }

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {}
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
                n.position = n.position + (input.boxSelectionWorld.end - editor.dragBoxPosition);
            }

            editor.dragBoxPosition = input.boxSelectionWorld.end;
        }
    }

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class Editor {
    Editor({
        this.selectedElements = const [],
        this.dragBoxPosition = Offset.infinite,
        this.dragBoxRadius = 10,
    }) {
        var nodes = [
            Node(0, 0, fixator: NodeFixator.hvt),
            Node(1, 0),
            Node(5, 0, fixator: NodeFixator.hvt),
            Node(9, 10),
            Node(-5, 5),
            Node(-9, 0),
        ];
        nodes.add(Node(7, 7));
        var beams = [
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
                force: Offset(22, 22),
            ),
        ];
        elements = List.from(beams)..addAll(nodes);
        bar = EditorBar(this);
        selectionState = EditorProcessSelectionState(this);
    }

    late List<EditorElement> elements;
    List<EditorElement> selectedElements;

    List<Node> get nodes {
        List<Node> list = [];
        for (final e in elements) {
            if (e is Node) list.add(e);
        }
        return list;
    }

    List<Beam> get beams {
        List<Beam> list = [];
        for (final e in elements) {
            if (e is Beam) list.add(e);
        }
        return list;
    }

    List<Node> get selectedNodes {
        List<Node> list = [];
        for (final e in elements) {
            if (e is Node && e.selected) list.add(e);
        }
        return list;
    }

    List<Beam> get selectedBeams {
        List<Beam> list = [];
        for (final e in elements) {
            if (e is Beam && e.selected) list.add(e);
        }
        return list;
    }

    Offset dragBoxPosition;
    late double dragBoxRadius;

    Grid grid = Grid();

    late EditorSelectionState selectionState;

    late EditorBar bar;

    FocusNode focus = FocusNode();

    void resetSelectionState() {
        selectionState = EditorProcessSelectionState(this);
    }

    void changeSelectionState(EditorSelectionState state) {
        selectionState = state;
    }

    void handleKeyboard(Input input) {
        if (input.keyboardEventBuffer.isEmpty) return;
        if (input.keyboardEventBuffer.last == LogicalKeyboardKey.delete) {
            input.keyboardEventBuffer.removeLast();
            deleteSelectedElements();
        }
    }

    void makeBeamsBetweenSelectedNodes() {
        final l = selectedNodes.length;
        for (int i = 0; i < l; i++) {
            for (int j = i; j < l; j++) {
                try {
                    elements.add(
                        Beam(
                            start: selectedNodes[i % l],
                            end: selectedNodes[j % l],
                            width: 1,
                            section: BeamSection.round,
                        ),
                    );
                }
                catch (identifier) {}
            }
        }
        resetSelectionState();
    }

    void addNodeInCenter(Offset pan) {
        elements.add(
            Node(pan.dx, pan.dy)
        );
        print("added node in ${pan}");
    }

    void deleteSelectedElements() {
        List<Node> nodesToRemove = [];
        List<Beam> beamsToRemove = [];
        for (final e in selectedElements) {
            if (e is Node) {
                for (final b in beams) {
                    if (e == b.start || e == b.end) {beamsToRemove.add(b);}
                }
                nodesToRemove.add(e);
            } else if (e is Beam) {
                beamsToRemove.add(e);
            }
        }

        for (final b in beamsToRemove) {
            if (beamsToRemove.contains(b)) beams.remove(b);
            if (beamsToRemove.contains(b)) elements.remove(b);
        }
        for (final n in nodesToRemove) {
            if (nodesToRemove.contains(n)) nodes.remove(n);
            if (nodesToRemove.contains(n)) elements.remove(n);
        }
        resetSelectionState();
    }

    void processInput(Window window, Input input) {
        handleKeyboard(input);
        selectionState.processInput(this, window, input);
    }

    void drawEditorElements(Window window, Painter painter) {
        for (final e in elements) {
            e.editorView.refreshCanvasData();
            e.editorView.render(window, painter);
        }
    }

    void drawDragBox(Window window, Painter painter, Input input) {
        Offset selectedCentersSum = Offset(0, 0);
        final int n = selectedElements.length;
        if (n > 0) {
            for (int i = 0; i < n; i++) {
                selectedCentersSum += selectedElements[i].center; 
            }
            dragBoxPosition = selectedCentersSum / n.toDouble();
            dragBoxRadius = 10 / window.zoom;

            final dragBoxPositionScreen = window.worldToScreen(dragBoxPosition);
            final lt = dragBoxPosition + Offset(-dragBoxRadius, dragBoxRadius);
            final rt = dragBoxPosition + Offset(dragBoxRadius, dragBoxRadius);
            final lb = dragBoxPosition + Offset(-dragBoxRadius, -dragBoxRadius);
            final rb = dragBoxPosition + Offset(dragBoxRadius, -dragBoxRadius);

            painter.setPaint(color: Colors.black.withOpacity(0.2), width: 1);
            painter.drawRect(
                window,
                Rect.fromPoints(
                    window.worldToScreen(lt),
                    window.worldToScreen(rb),
                )
            );

            final mouseInDragBox = Rect.fromCircle(
                center: dragBoxPosition,
                radius: dragBoxRadius,
            ).contains(input.mousePosWorld);
            const double triangleHeight = 20;
            const double triangleOpacity = 0.80;
            final double triangleLight = (mouseInDragBox) ? 0.33 : 0;

            painter.setPaint(color: pinkColor.lighter(triangleLight / 1.5).withOpacity(triangleOpacity), width: 1);
            painter.drawTriangle(
                window,
                window.worldToScreen(lt),
                window.worldToScreen(lb),
                dragBoxPositionScreen - Offset(triangleHeight, 0),
            );
            painter.drawTriangle(
                window,
                window.worldToScreen(rt),
                window.worldToScreen(rb),
                dragBoxPositionScreen + Offset(triangleHeight, 0),
            );
            painter.setPaint(color: cianColor.lighter(triangleLight).withOpacity(triangleOpacity), width: 1);
            painter.drawTriangle(
                window,
                window.worldToScreen(lt),
                window.worldToScreen(rt),
                dragBoxPositionScreen - Offset(0, triangleHeight),
            );
            painter.drawTriangle(
                window,
                window.worldToScreen(lb),
                window.worldToScreen(rb),
                dragBoxPositionScreen + Offset(0, triangleHeight),
            );
        }
    }

    void drawEditorElementsUI(Window window, Painter painter) {
        for (final e in elements) {
            e.editorView.renderUI(window, painter);
        }
    }

    void render(Window window, Painter painter, Input input) {
        grid.render(window, painter);
        drawEditorElements(window, painter);
        if (bar.elementsUIVisible) drawEditorElementsUI(window, painter);
        selectionState.drawBoxSelection(window, painter, input);
        drawDragBox(window, painter, input);
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

        painter.setPaint(color: cianColor.darker(0.2), width: 3);
        painter.drawLine(
            window,
            Offset(window.pan.dx, 0),
            Offset(window.pan.dx, window.height),
        );

        painter.setPaint(color: pinkColor.darker(0.2), width: 3);
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
                    bgColor: clamped ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0),
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
    EditorBar(this.editor);

    Editor editor;
    List<bool> _selectionMode = [true, false];
    List<bool> _hideElementsUI = [true];

    bool get isBeamSelectionMode => _selectionMode[0];
    bool get isNodeSelectionMode => _selectionMode[1];

    bool get elementsUIVisible => _hideElementsUI[0];

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
            color: amberColor.lighter(0.8),
            padding: const EdgeInsets.all(5.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                    Row(
                        children: [
                            ToggleButtons(
                                onPressed: (int index) {
                                    setState(() {
                                        widget.unselectAllElements();
                                        for (int i = 0; i < widget._selectionMode.length; i++) {
                                            widget._selectionMode[i] = i == index;
                                        }
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: widget._selectionMode,
                                children: selectionModeIcons,
                            ),
                            SizedBox(width: 24),
                            ToggleButtons(
                                onPressed: (int _) {
                                    setState(() {
                                        widget._hideElementsUI[0] = !widget._hideElementsUI[0];
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: widget._hideElementsUI,
                                children: widget._hideElementsUI[0] ? [Icon(CadIcons.eye)] : [Icon(CadIcons.eyeOff)],
                            ),
                        ],
                    ),

                    Row(
                        children: [
                            ToggleButtons(
                                onPressed: (int _) {
                                    setState(() {
                                        widget._hideElementsUI[0] = !widget._hideElementsUI[0];
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: widget._hideElementsUI,
                                children: widget._hideElementsUI[0] ? [Icon(CadIcons.eye)] : [Icon(CadIcons.eyeOff)],
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}


class EditorOperationsBar extends StatefulWidget {
    EditorOperationsBar(this.editor, this.window);

    Editor editor;
    Window window;

    @override
    State<EditorOperationsBar> createState() => _EditorOperationsBarState();
}


class _EditorOperationsBarState extends State<EditorOperationsBar> {
    bool _visible = false;
    bool _changed = true;

    @override
    Widget build(BuildContext context) {
        if (_changed) {
            _changed = false;
            return Container();
        }
        _visible = !widget.editor.selectedElements.isEmpty;
        return Container(
            padding: const EdgeInsets.all(5.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                    Visibility(
                        maintainSize: true, 
                        maintainAnimation: true,
                        maintainState: true,
                        visible: _visible, 
                        child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                IconButton.filled(
                                    onPressed: () {}, icon: const Icon(Icons.filter_drama)),
                                SizedBox(width: 20),
                                IconButton(
                                    isSelected: true,
                                    icon: const Icon(Icons.settings_outlined),
                                    selectedIcon: const Icon(Icons.settings),
                                    onPressed: () {},
                                ),
                                SizedBox(width: 20),
                                MaterialButton(
                                    height: 55,
                                    minWidth: 40,
                                    onPressed: () {
                                        setState(() {
                                            widget.editor.addNodeInCenter(widget.window.panWorld);
                                            _visible = false;
                                            _changed = true;
                                        });
                                    },
                                    color: cianColor.darker(0.2),
                                    textColor: Colors.white,
                                    child: const Icon(
                                       CadIcons.addPlus,
                                       size: 32,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                ),
                                SizedBox(width: 20),
                                widget.editor.bar.isNodeSelectionMode ? MaterialButton(
                                    height: 55,
                                    minWidth: 40,
                                    onPressed: () {
                                        setState(() {
                                            widget.editor.makeBeamsBetweenSelectedNodes();
                                            _visible = false;
                                            _changed = true;
                                        });
                                    },
                                    color: cianColor.darker(0.2),
                                    textColor: Colors.white,
                                    child: const Icon(
                                       CadIcons.cheese,
                                       size: 32,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                ) : SizedBox.shrink(),
                                widget.editor.bar.isNodeSelectionMode ? SizedBox(width: 20) : SizedBox.shrink(),
                                MaterialButton(
                                    height: 55,
                                    minWidth: 40,
                                    onPressed: () {
                                        setState(() {
                                            widget.editor.deleteSelectedElements();
                                            _visible = false;
                                            _changed = true;
                                        });
                                    },
                                    color: pinkColor.darker(0.2),
                                    textColor: Colors.white,
                                    child: const Icon(
                                       CadIcons.delete,
                                       size: 32,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}
