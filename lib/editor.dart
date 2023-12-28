import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scidart/numdart.dart';

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
    bool click(Window window, Offset mouseWorldClick) => true;
    bool boxSelect(BoxSelection selection) => true;
    void refreshCanvasData() {}
}


abstract class EditorElement {
    EditorElement({
        this.selected = false,
    });

    Offset get center;
    Offset get position;
    set position(Offset p);
    double get length;

    bool selected;

    late InspectorView inspectorView;
    late EditorView editorView;

    List<Node> getElementNodes() => [];
}


class Node implements EditorElement {
    Node(double x, double y, {
        this.selected = false,
        this.force = const Offset(0, 0),
        this.torqueForce = 0,
        this.fixator = NodeFixator.disabled,
    }) {
        this._position = Offset(x, y);
        this.editorView = NodeEditorView(this);
        this.inspectorView = NodeInspectorView(this);

        this.index = _globalIndex;
        _globalIndex++;
    }

    static int _globalIndex = 0;
    late int index;

    /// Data
    Offset _position = Offset.infinite;
    Offset force;
    double torqueForce;
    NodeFixator fixator;

    static void resetNodeIndex() => _globalIndex = 0;

    Offset operator +(Offset other) => Offset(_position.dx + other.dx, _position.dy + other.dy);
    Offset operator -(Offset other) => Offset(_position.dx - other.dx, _position.dy - other.dy);

    @override
    bool selected;

    @override
    late EditorView editorView;

    @override
    late InspectorView inspectorView;

    @override
    Offset get center => _position;

    @override
    Offset get position => _position;

    @override
    set position(Offset p) => _position = p;

    @override
    double get length => 0;

    @override
    List<Node> getElementNodes() {
        return [this];
    }

    factory Node.fromJson(dynamic json) {
        final force = Offset(
            json['forceX'] as double,
            json['forceY'] as double,
        );

        NodeFixator fixator = NodeFixator.values.firstWhere((e) => e.toString() == "NodeFixator.${json['fixator']}");

        return Node(
            json['positionX'] as double,
            json['positionY'] as double,
            force: force,
            fixator: fixator,
        );
    }

    Map toJson() => {
        'positionX': position.dx,
        'positionY': position.dy,
        'forceX': force.dx,
        'forceY': force.dy,
        'fixator': fixator.name,
    };
}


class NodeEditorView implements EditorView {
    NodeEditorView(this.editorElement);
    static const double radius = 10;
    static const double fixatorRadius = 15;
    static const double forceLabelOffset = 17;
    static const double forceLabelFontSize = 16;

    @override
    final editorElement;

    void drawForceArrows(Window window, Painter painter) {
        if (editorElement.force.dx != 0 || editorElement.force.dy != 0) {
            final double arrowWidth = radius / 3;
            final double arrowLength = 40 / window.zoom;
            final double triangleRadius = radius / window.zoom;

            final double flipX = editorElement.force.dx >= 0 ? 1 : -1;
            final double flipY = editorElement.force.dy >= 0 ? 1 : -1;
            final Offset yArrowEnd = editorElement.position + Offset(0, arrowLength) * flipY;
            final Offset xArrowEnd = editorElement.position + Offset(arrowLength, 0) * flipX;
            final Offset yTrianglePoint = yArrowEnd + Offset(triangleRadius, 0) * flipY;
            final Offset xTrianglePoint = xArrowEnd + Offset(triangleRadius, 0) * flipX;

            const Offset forceLabelOffset = Offset(0, -15);

            painter.setPaint(color: purpleColor.color, width: arrowWidth);

            var a = rotatePoint(yArrowEnd, yTrianglePoint, -pi / 6 * flipY);
            var b = rotatePoint(yArrowEnd, yTrianglePoint, -3 * pi / 2 * flipY);
            var c = rotatePoint(yArrowEnd, yTrianglePoint, -5 * pi / 6 * flipY);

            /*
            painter.drawTriangle(
                window,
                window.worldToScreen(a),
                window.worldToScreen(b),
                window.worldToScreen(c),
            );
            painter.drawLine(
                window,
                window.worldToScreen(editorElement.position),
                window.worldToScreen(yArrowEnd),
            );

            painter.drawText(
                window: window,
                text: '${editorElement.force.dy.toStringAsFixed(2)}',
                fontSize: forceLabelFontSize,
                textColor: Colors.black,
                bgColor: Color(0x00ffffff),
                textOffset: window.worldToScreen(b) + forceLabelOffset / 2,
                outline: true,
                outlineSize: 1.25,
                centerAlignX: true,
                centerAlignY: true,
            );
            */

            painter.setPaint(color: purpleColor.color, width: arrowWidth);

            a = rotatePoint(xArrowEnd, xTrianglePoint, 0);
            b = rotatePoint(xArrowEnd, xTrianglePoint, 2 * pi / 3 * flipX);
            c = rotatePoint(xArrowEnd, xTrianglePoint, 4 * pi / 3 * flipX);
            painter.drawTriangle(
                window,
                window.worldToScreen(a),
                window.worldToScreen(b),
                window.worldToScreen(c),
            );
            painter.drawLine(
                window,
                window.worldToScreen(editorElement.position),
                window.worldToScreen(xArrowEnd),
            );
            painter.drawText(
                window: window,
                text: '${editorElement.force.dx.toStringAsFixed(2)}',
                fontSize: forceLabelFontSize,
                textColor: Colors.black,
                bgColor: const Color(0x00ffffff),
                textOffset: window.worldToScreen(a) - forceLabelOffset,
                outline: true,
                outlineSize: 1.25,
                centerAlignX: true,
                centerAlignY: true,
            );
        }
    }

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
        drawForceArrows(window, painter);
    }

    @override
    bool click(Window window, Offset mouseWorldClick) {
        editorElement.selected = Rect.fromCircle(
            center: editorElement.position,
            radius: radius,
        ).contains(mouseWorldClick);
        editorElement.selected = isPointInCircle(mouseWorldClick, editorElement.position, radius * (1 / window.zoom));
        return editorElement.selected;
    }

    @override
    bool boxSelect(BoxSelection selection) {
        editorElement.selected = isPointInRect(editorElement.center, selection.start, selection.end);
        return editorElement.selected;
    }

    @override
    void refreshCanvasData() {}
}


class Beam implements EditorElement {
    Beam({
        required this.start,
        required this.end,
        this.force = const Offset(0, 0),
        //this.width = 1,
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
    //double width;
    double sectionArea;
    double elasticity;
    double tension;
    BeamSection section;


    double get rotation { 
        final delta = Offset(end.position.dx - start.position.dx, end.position.dy - start.position.dy);
        return atan(delta.dy / delta.dx);
    }

    @override
    double get length => Offset(start.position.dx - end.position.dx, start.position.dy - end.position.dy).distance;

    @override
    bool selected;

    @override
    late EditorView editorView;

    @override
    late InspectorView inspectorView;

    @override
    Offset get center => Offset(start.position.dx + end.position.dx, start.position.dy + end.position.dy) / 2;

    @override
    Offset get position => center;

    @override
    set position(Offset value) {
        final offset = center - value;
        start.position -= offset;
        end.position -= offset;
    }

    @override
    List<Node> getElementNodes() {
        return [start, end];
    }

    factory Beam.fromJson(dynamic json, List<Node> nodes) {
        final force = Offset(
            json['forceX'] as double,
            json['forceY'] as double,
        );

        int startI = json['startI'].toInt();
        int endI = json['endI'].toInt();

        return Beam(
            start: nodes[startI],
            end: nodes[endI],
            force: force,
            sectionArea: json['sectionArea'] as double,
            elasticity: json['elasticity'] as double,
            tension: json['tension'] as double, 
        );
    }

    Map toJson() {
        print(start.index);
        print(end.index);
    return {
        'startI': start.index,
        'endI': end.index,
        'forceX': force.dx,
        'forceY': force.dy,
        'sectionArea': sectionArea,
        'elasticity': elasticity,
        'tension': tension,
    };}
}


class BeamEditorView implements EditorView {
    BeamEditorView(this.editorElement);

    static const double centerCrossLength = 7;
    static const double forceLabelOffset = 25;
    static const double forceLabelFontSize = 16;

    @override
    final editorElement;

    late Offset a, b, c, d;

    @override
    void render(Window window, Painter painter) {
        painter.setPaint(color: editorElement.selected ? cianColor.darker(0.3) : Colors.grey.shade700);
        painter.drawQuad(window, a, b, c, d);

        painter.setPaintStroke(color: Colors.black, width: 3);
        painter.drawQuadStroke(window, a, b, c, d);
    }

    void drawForceArrows(Window window, Painter painter) {
        const double tScale = 0.66;

        painter.setPaint(color: pinkColor.color);
        if (editorElement.force.dx != 0) {
            final bool xForcePositive = editorElement.force.dx > 0;

            Offset beamVec = xForcePositive ? editorElement.end.position - editorElement.start.position :
                                              editorElement.start.position - editorElement.end.position;

            Offset triangleStep = beamVec / window.zoom / editorElement.length * 10;
            Offset gapStep = triangleStep;

            Offset aPos = xForcePositive ? c - (c - editorElement.end.position) / tScale :
                                           a - (a - editorElement.start.position) / tScale;
            Offset bPos = xForcePositive ? d - (d - editorElement.end.position) / tScale :
                                           b - (b - editorElement.start.position) / tScale;
            Offset hPos = xForcePositive ? editorElement.end.position + triangleStep :
                                           editorElement.start.position + triangleStep;

            double length = 0;
            double maxLength = editorElement.length - triangleStep.distance;

            while (length <= maxLength) {
                Offset aPosNew = aPos - triangleStep;
                Offset bPosNew = bPos - triangleStep;
                Offset hPosNew = hPos - triangleStep;

                painter.drawTriangle(
                    window,
                    window.worldToScreen(aPosNew),
                    window.worldToScreen(bPosNew),
                    window.worldToScreen(hPosNew),
                );

                aPos = aPosNew - gapStep;
                bPos = bPosNew - gapStep;
                hPos = hPosNew - gapStep;

                length += triangleStep.distance + gapStep.distance;
            }
        }
    }

    void drawBeamCenter(Window window, Painter painter) {
        var beamCenterOnScreen = window.worldToScreen(editorElement.center);
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
                bgColor: const Color(0x00ffffff),
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
    bool click(Window window, Offset mouseWorldClick) {
        refreshCanvasData();
        editorElement.selected = isPointInQuad(mouseWorldClick, a, b, c, d);
        return editorElement.selected;
    }

    @override
    bool boxSelect(BoxSelection selection) {
        editorElement.selected = isPointInRect(editorElement.start.center, selection.start, selection.end) &&
                                 isPointInRect(editorElement.end.center, selection.start, selection.end);
        return editorElement.selected;
    }

    @override
    void refreshCanvasData() {
        a = rotatePoint(
            editorElement.start.position,
            Offset(editorElement.start.position.dx, editorElement.start.position.dy + editorElement.sectionArea / 2),
            editorElement.rotation,
        );
        b = rotatePoint(
            editorElement.start.position,
            Offset(editorElement.start.position.dx, editorElement.start.position.dy - editorElement.sectionArea / 2),
            editorElement.rotation,
        );
        c = rotatePoint(
            editorElement.end.position,
            Offset(editorElement.end.position.dx, editorElement.end.position.dy + editorElement.sectionArea / 2),
            editorElement.rotation,
        );
        d = rotatePoint(
            editorElement.end.position,
            Offset(editorElement.end.position.dx, editorElement.end.position.dy - editorElement.sectionArea / 2),
            editorElement.rotation,
        );
    }
}


abstract class EditorSelectionState {
    void processInput(Editor editor, Window window, Input input) {}
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class EditorInitialSelectionState implements EditorSelectionState {
    EditorInitialSelectionState(Editor editor) {
        for(final e in editor.elements) {
            e.selected = false;
        }
    }

    @override
    void processInput(Editor editor, Window window, Input input) {
        if (editor.selectedElements.isNotEmpty && (!input.isLMBDown)) {
            editor.changeSelectionState(EditorSelectionDoneState(editor));
        }

        editor.selectedElements = [];
        final BoxSelection selection = input.boxSelectionWorld;
        final list = editor.isBeamSelectionMode ? editor.beams : editor.nodes;

        if (selection.start != selection.end) {
            for (final c in list) {
                final select = c.editorView.boxSelect(input.boxSelectionWorld);
                if (select) {
                    editor.selectedElements.add(c);
                }        
            }   
        } else {
            for (final c in list.reversed.toList()) {
                if (c.editorView.click(window, input.lMBWorldClick)) {
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
        final BoxSelection selection = input.boxSelectionWorld;
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


class EditorSelectionDoneState implements EditorSelectionState {
    EditorSelectionDoneState(Editor editor);

    @override
    void processInput(Editor editor, Window window, Input input) {
        final mouseInDragBox = Rect.fromCircle(
            center: editor.dragBoxPosition,
            radius: editor.dragBoxRadius,
        ).contains(input.mousePosWorld);

        if (input.isLMBDown && mouseInDragBox) {
            editor.changeSelectionState(EditorDragSelectedState(editor));
        } else if (input.isLMBDown && !mouseInDragBox) {
            editor.changeSelectionState(EditorInitialSelectionState(editor));
        }
    }

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class EditorDragSelectedState implements EditorSelectionState {
    EditorDragSelectedState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        if (!input.isLMBDown) {
            editor.changeSelectionState(EditorSelectionDoneState(editor));
        } else {
            final Set<Node> nodes = {};
            for (final e in editor.selectedElements) {
                for (final node in e.getElementNodes()) {
                    nodes.add(node);
                }
            }

            final endPos = input.boxSelectionWorld.getEndSnapped();
            for (final n in nodes) {
                n.position = n.position + (endPos - editor.dragBoxPosition);
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
        this.elementsUIVisible = true,
        this.showCalcOverlay = false,
    }) {
        selectionState = EditorInitialSelectionState(this);
    }

    List<EditorElement> elements = [];
    List<EditorElement> selectedElements;

    Offset dragBoxPosition;
    late double dragBoxRadius;

    Grid grid = Grid();

    bool isBeamSelectionMode = true;
    bool elementsUIVisible;
    bool showCalcOverlay;
    late EditorSelectionState selectionState;

    FocusNode focus = FocusNode();

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

    List<Node> get nodesReversed {
        List<Node> list = [];
        for (final e in elements) {
            if (e is Node) list.add(e);
        }
        return List.from(list.reversed);
    }

    List<Beam> get beamsReversed {
        List<Beam> list = [];
        for (final e in elements) {
            if (e is Beam) list.add(e);
        }
        return List.from(list.reversed);;
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

    void clearAllElements() {
        elements = [];
        Node.resetNodeIndex();
        resetSelectionState();
    }

    void resetSelectionState() {
        selectionState = EditorInitialSelectionState(this);
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
                    elements.insert(
                        0, 
                        Beam(
                            start: selectedNodes[i % l],
                            end: selectedNodes[j % l],
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
        if (selectedElements.isNotEmpty) {
            dragBoxPosition = avgPoint(selectedElements.map((e) => e.center).toList());
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
                dragBoxPositionScreen - const Offset(triangleHeight, 0),
            );
            painter.drawTriangle(
                window,
                window.worldToScreen(rt),
                window.worldToScreen(rb),
                dragBoxPositionScreen + const Offset(triangleHeight, 0),
            );
            painter.setPaint(color: cianColor.lighter(triangleLight).withOpacity(triangleOpacity), width: 1);
            painter.drawTriangle(
                window,
                window.worldToScreen(lt),
                window.worldToScreen(rt),
                dragBoxPositionScreen - const Offset(0, triangleHeight),
            );
            painter.drawTriangle(
                window,
                window.worldToScreen(lb),
                window.worldToScreen(rb),
                dragBoxPositionScreen + const Offset(0, triangleHeight),
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
        if (elementsUIVisible) drawEditorElementsUI(window, painter);
        selectionState.drawBoxSelection(window, painter, input);
        drawDragBox(window, painter, input);
    }
}


class Grid {
    static bool snap = true;
    static double snapLevel = 1.0;

    void drawMainAxis(Window window, Painter painter) {
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
    }

    void draw(Window window, Painter painter) {
        final double depthPower = floorToPowerOfTwo(window.zoom);
        final double depth = 1 / depthPower;
        final double step = 32 * depth;
        const double gridSteps = 5;
        final double drawStopper = max(window.width, window.height);
        final int decimalLevel = (depthPower / 32).clamp(0, 6).toInt();

        /// Draw minor gridlines
        final double minorStep = step * window.zoom;
        Offset screenPan = window.pan % minorStep - Offset(minorStep, minorStep);

        final Offset inc = Offset(1, 1) * minorStep;
        painter.setPaint(color: Colors.grey, width: 1);
        for (Offset i = screenPan; i < Offset(drawStopper, drawStopper); i += inc) {
            painter.drawLine(window, Offset(i.dx, 0), Offset(i.dx, window.height));
            painter.drawLine(window, Offset(0, i.dy), Offset(window.width, i.dy));
        }

        /// Draw major gridlines
        final double majorStep = step * gridSteps * window.zoom;
        screenPan = window.pan % majorStep;

        final Offset inc2 = Offset(1, 1) * majorStep;
        painter.setPaint(color: Colors.black, width: 1.5);
        for (Offset i = screenPan; i.dx < drawStopper; i += inc2) {
            painter.drawLine(window, Offset(i.dx, 0), Offset(i.dx, window.height));
            painter.drawLine(window, Offset(0, i.dy), Offset(window.width, i.dy));
        }

        /// Draw main axis and text labels (coordinates)
        const double border = 20;
        final double borderHeight = window.height - 1.1 * border;
        final double borderWidth = window.width - 1.5 * border;

        final double offsetX = window.pan.dx.clamp(border, borderWidth);
        final double offsetY = window.pan.dy.clamp(border, borderHeight);
        final bool clampedX = (offsetX == border || offsetX == borderWidth);
        final bool clampedY = (offsetY == border || offsetY == borderHeight);
        final Color textColorX = clampedX ? Colors.grey.shade600 : Colors.black;
        final Color textColorY = clampedY ? Colors.grey.shade600 : Colors.black;
        final Color bgColorX = clampedX ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0);
        final Color bgColorY = clampedY ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0);

        drawMainAxis(window, painter);

        for (Offset i = screenPan; i.dx < drawStopper; i += inc2) {
            final Offset coord = window.screenToWorld(i);

            final Offset textOffsetX = Offset(offsetX, i.dy);
            final Offset textOffsetY = Offset(i.dx, offsetY);
            final String textX = coord.dx.toStringAsFixed(decimalLevel);
            final String textY = coord.dy.toStringAsFixed(decimalLevel);

            if (coord.dy.abs() > 1e-9) {
                painter.drawText(
                    window: window,
                    text: textY,
                    fontSize: 18,
                    textColor: textColorX,
                    bgColor: bgColorX,
                    outline: !clampedX,
                    textOffset: textOffsetX,
                    centerAlignX: true,
                    centerAlignY: true,
                );
            }

            if (coord.dx.abs() > 1e-9) {
                painter.drawText(
                    window: window,
                    text: textX,
                    fontSize: 18,
                    textColor: textColorY,
                    bgColor: bgColorY,
                    outline: !clampedY,
                    textOffset: textOffsetY,
                    centerAlignX: true,
                    centerAlignY: true,
                );
            }
        }
    }

    void render(Window window, Painter painter) {
        draw(window, painter);
    }
}


class EditorBar extends StatefulWidget {
    EditorBar(this.editor, {
        this.width,
        this.height,
    });

    final Editor editor;
    final double? width;
    final double? height;

    @override
    State<EditorBar> createState() => _EditorBarState();
}


class _EditorBarState extends State<EditorBar> {
    List<bool> _selectionMode = [true, false];

    TextInputFormatter _formatter = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));

    bool get _isBeamSelectionMode => _selectionMode[0];

    void _unselectAllElements() {
        widget.editor.resetSelectionState();
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: widget.width,
            height: widget.height,
            color: purpleColor.lighter(0.9),
            padding: const EdgeInsets.all(5.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                    Column(
                        children: [
                            ToggleButtons(
                                onPressed: (int index) {
                                    setState(() {
                                        _unselectAllElements();
                                        for (int i = 0; i < _selectionMode.length; i++) {
                                            _selectionMode[i] = i == index;
                                        }
                                        widget.editor.isBeamSelectionMode = _selectionMode[0];
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: _selectionMode,
                                children: selectionModeIcons,
                            ),
                        ],
                    ),

                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: pinkColor.darker(0.0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16.0),
                            textStyle: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                            Calculation calc = Calculation();
                            widget.editor.showCalcOverlay = calc.isElementsValid(widget.editor.beams);
                        },
                        child: const Text('Delta'),
                    ),

                    Column(
                        children: [
                            ToggleButtons(
                                onPressed: (int _) {
                                    setState(() {
                                        Grid.snap = !Grid.snap;
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: [Grid.snap],
                                children: [Icon(CadIcons.snapToGrid, size: 32.0)],
                            ),
                        ],
                    ),

                    SizedBox(
                        height: 60.0,
                        width: 100,
                        child: TextField(
                            controller: TextEditingController(text: Grid.snapLevel.toStringAsFixed(6)),
                            //decoration: InputDecoration(labelText: "123"),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                                _formatter,
                            ],
                            onSubmitted: (value) => Grid.snapLevel = double.parse(value),
                        ),
                    ),

                    Column(
                        children: [
                            ToggleButtons(
                                onPressed: (int _) {
                                    setState(() {
                                        widget.editor.elementsUIVisible = !widget.editor.elementsUIVisible;
                                    });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                selectedBorderColor: cianColor.darker(0.3),
                                selectedColor: Colors.white,
                                disabledBorderColor: Colors.white,
                                disabledColor: Colors.white,
                                fillColor: cianColor.darker(0.2),
                                color: cianColor.darker(0.2),
                                isSelected: [widget.editor.elementsUIVisible],
                                children:  widget.editor.elementsUIVisible ? [Icon(CadIcons.eye)] : [Icon(CadIcons.eyeOff)],
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}


class EditorOperationsBar extends StatefulWidget {
    EditorOperationsBar(
        this.editor,
        this.window, {
        this.width,
        this.height,
    });

    final Editor editor;
    final Window window;
    final double? width;
    final double? height;

    @override
    State<EditorOperationsBar> createState() => _EditorOperationsBarState();
}


class _EditorOperationsBarState extends State<EditorOperationsBar> {
    static const double buttonHeight = 55;
    static const double minWidth = 40;
    static const double darkness = 0.2;
    static const double iconSize = 32;
    static const double roundness = 8;
    static const double padding = 5;
    static const double spaceBetween = 20;

    bool _visible = true;
    bool _changed = true;

    @override
    Widget build(BuildContext context) {
        if (_changed) {
            _changed = false;
            return Container();
        }
        _visible = !widget.editor.selectedElements.isEmpty;
        final isBeamSelectionMode = widget.editor.isBeamSelectionMode;
        return Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.all(padding),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            SizedBox(width: 47),
                            !isBeamSelectionMode ? MaterialButton(
                                height: buttonHeight,
                                minWidth: minWidth,
                                onPressed: () {
                                    setState(() {
                                        widget.editor.addNodeInCenter(widget.window.panWorld);
                                        _visible = false;
                                        _changed = true;
                                    });
                                },
                                color: cianColor.darker(darkness),
                                textColor: Colors.white,
                                child: const Icon(
                                   CadIcons.addPlus,
                                   size: iconSize,
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: const BorderRadius.all(const Radius.circular(roundness))),
                            ) : SizedBox.shrink(),
                            !isBeamSelectionMode && widget.editor.selectedElements.length >= 2 ? SizedBox(width: spaceBetween) : SizedBox.shrink(),
                            !isBeamSelectionMode && widget.editor.selectedElements.length >= 2 ? MaterialButton(
                                height: buttonHeight,
                                minWidth: minWidth,
                                onPressed: () {
                                    setState(() {
                                        widget.editor.makeBeamsBetweenSelectedNodes();
                                        _visible = false;
                                        _changed = true;                                        
                                    });
                                },
                                color: cianColor.darker(darkness),
                                textColor: Colors.white,
                                child: const Icon(
                                   CadIcons.cheese,
                                   size: iconSize,
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: const BorderRadius.all(const Radius.circular(roundness))),
                            ) : SizedBox.shrink(),
                            !isBeamSelectionMode ? SizedBox(width: spaceBetween) : SizedBox.shrink(),
                            _visible ? MaterialButton(
                                height: buttonHeight,
                                minWidth: minWidth,
                                onPressed: () {
                                    setState(() {
                                        widget.editor.deleteSelectedElements();
                                        _visible = false;
                                        _changed = true;
                                    });
                                },
                                color: pinkColor.darker(darkness),
                                textColor: Colors.white,
                                child: const Icon(
                                   CadIcons.delete,
                                   size: iconSize,
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: const BorderRadius.all(const Radius.circular(roundness))),
                            ) : SizedBox.shrink(),
                        ],
                    ),
                ],
            ),
        );
    }
}

class CalculationOverlay extends StatefulWidget {
    CalculationOverlay(
        this.editor, {
        this.width,
        this.height,
        this.title = "Calculation results",

    });

    final Editor editor;
    final String title;
    final double? width;
    final double? height;

    @override
    State<CalculationOverlay> createState() => _CalculationOverlayState();
}

class _CalculationOverlayState extends State<CalculationOverlay> {
    static const double buttonHeight = 55;
    static const double minWidth = 40;
    static const double darkness = 0.2;
    static const double iconSize = 32;
    static const double roundness = 8;

    final Calculation calc = Calculation();

    @override
    Widget build(BuildContext context) {
        if (!widget.editor.showCalcOverlay) return SizedBox.shrink();

        final List<Beam> beams = widget.editor.beamsReversed;
        calc.isElementsValid(beams);

        final List<double> deltas = calc.getDeltas(beams);
        final List<double> normalTensions = calc.getNormalTensions(beams, deltas);

        final String deltasStr = deltas != null ? deltas.toString() : "";
        final String normalTensionsStr = normalTensions != null ? normalTensions.toString() : "";

        return Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            color: Colors.white,
            child: Column(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.all(5.0),
                        child: MaterialButton(
                            height: buttonHeight,
                            minWidth: minWidth,
                            onPressed: () {
                                setState(() {
                                    widget.editor.showCalcOverlay = false;
                                });
                            },
                            color: pinkColor.darker(darkness),
                            textColor: Colors.white,
                            child: const Icon(
                               CadIcons.cheese,
                               size: iconSize,
                            ),
                            shape: const RoundedRectangleBorder(
                                borderRadius: const BorderRadius.all(const Radius.circular(roundness)),
                            ),
                        ),
                    ),
                    Text(widget.title),
                    Text("Delta: $deltasStr"),
                    Text("Normal tensions: $normalTensionsStr"),
                ],
            ),
        );
    }
}


class Calculation {
    double k(Beam beam) => beam.elasticity * beam.sectionArea / beam.length;

    bool isElementsValid(List<Beam> beams) {
        return true;

        // TODO: fix bug: always return false (skip for loop)
        /*
        if (beams.isNotEmpty) { return true; }
        for (final b in beams) {
            if (b.start.fixator != NodeFixator.disabled || b.end.fixator != NodeFixator.disabled) { return true; }
        }
        return false;
        */
    }

    Array2d _getMatrixA(List<Beam> beams) {
        final int beamsLength = beams.length;
        var matrix = Array2d.empty();

        var firstLine = Array(List.from([k(beams[0]), -k(beams[0])])
            ..addAll(List<double>.filled(beamsLength - 1, 0.0)));
        matrix.add(firstLine);

        for (int i = 1; i < beamsLength; i++) {
            final line = Array(List.from(List<double>.filled(i - 1, 0.0))
                ..addAll([-k(beams[i - 1]), k(beams[i - 1]) + k(beams[i]), -k(beams[i])])
                ..addAll(List<double>.filled(beamsLength - i - 1, 0.0)));
            matrix.add(line);
        }

        var lastLine = Array(List.from(List<double>.filled(beamsLength - 1, 0.0))
            ..addAll([-k(beams[beamsLength - 1]), k(beams[beamsLength - 1])]));
        matrix.add(lastLine);

        if (beams.first.start.fixator != NodeFixator.disabled) {
            matrix[0][0] = 1;
            matrix[0][1] = 0;
            matrix[1][0] = 0;
        }
        if (beams.last.end.fixator != NodeFixator.disabled) {
            matrix[beamsLength][beamsLength] = 1;
            matrix[beamsLength - 1][beamsLength] = 0;
            matrix[beamsLength][beamsLength - 1] = 0;
        }

        print(matrix);

        return matrix;
    }

    double q(double q, double l) => -(q * l) / 2;
    Array2d _getMatrixB(List<Beam> beams) {
        final int beamsLength = beams.length;
        var matrix = Array2d.empty();

        matrix.add(beams.first.start.fixator == NodeFixator.disabled ?
            Array([-q(beams.first.force.dx, beams.first.length) - beams.first.start.force.dx])
            : Array([0.0]));
        for (int i = 1; i < beamsLength; i++) {
            matrix.add(Array([-q(beams[i - 1].force.dx, beams[i - 1].length) - q(beams[i].force.dx, beams[i].length) + beams[i].start.force.dx]));
        }
        matrix.add(beams.last.end.fixator == NodeFixator.disabled ?
            Array([-q(beams.last.force.dx, beams.last.length) - beams.last.start.force.dx])
            : Array([0.0]));

        print("B matrix:");
        print(matrix);
        return matrix;
    }

    List<double> getDeltas(List<Beam> beams) {
        try {
            final a = _getMatrixA(beams);
            final b = _getMatrixB(beams);
            final deltas = matrixSolve(a, b).getColumn(0);
            print(deltas);
            return deltas != null ? deltas.toList() : [];
        } catch (e) {
            print(e);
            return [];
        }
    }

    double normalTension(
        Beam beam,
        double deltaA,
        double deltaB,
        double lengthCum,
    ) {
        return (beam.elasticity * beam.sectionArea) * (deltaA - deltaB) / beam.length + (beam.force.dx * beam.length / 2) * (1 - 2 * lengthCum / beam.length);
    }

    List<double> getNormalTensions(List<Beam> beams, List<double> deltas) {
        try {
            List<double> normalTensions = [];
            double lengthCum = 0;

            for (int i = 0; i < beams.length; i++) {
                normalTensions.add(normalTension(beams[i], deltas[i], deltas[i + 1], lengthCum));
                lengthCum += beams[i].length;
                normalTensions.add(normalTension(beams[i], deltas[i], deltas[i + 1], lengthCum));
            }

            print(normalTensions);
            return normalTensions;
        } catch (e) {
            print(e);
            return [];
        }
    }
}
