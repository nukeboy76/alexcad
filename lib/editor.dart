import 'dart:async';
import 'dart:io';
import 'dart:convert';
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

        this.index = globalIndex;
        globalIndex++;
    }

    static int globalIndex = 0;
    late int index;

    /// Data
    Offset _position = Offset.infinite;
    Offset force;
    double torqueForce;
    NodeFixator fixator;

    static void resetNodeIndex() => globalIndex = 0;

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
        final color = editorElement.selected ? cianColor.darker(0.3) : Colors.grey.shade700;
        painter.setPaint(color: color);
        painter.drawQuad(window, a, b, c, d);
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
            editor.changeSelectionState(EditorDoneSelectionState(editor));
        }

        editor.selectedElements = [];
        final start = input.boxSelectionWorld.start;
        final end = input.boxSelectionWorld.end;
        final list = editor.isBeamSelectionMode ? editor.beams : editor.nodes;

        if (start != end) {
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


class EditorDoneSelectionState implements EditorSelectionState {
    EditorDoneSelectionState(Editor editor);
    @override
    void processInput(Editor editor, Window window, Input input) {
        final mouseInDragBox = Rect.fromCircle(
            center: editor.dragBoxPosition,
            radius: editor.dragBoxRadius,
        ).contains(input.mousePosWorld);

        if (input.isLMBDown && mouseInDragBox) {
            editor.changeSelectionState(EditorInitialSelectedState(editor));
        } else if (input.isLMBDown && !mouseInDragBox) {
            editor.changeSelectionState(EditorInitialSelectionState(editor));
        }
    }

    @override
    void drawBoxSelection(Window window, Painter painter, Input input) {}
}


class EditorInitialSelectedState implements EditorSelectionState {
    EditorInitialSelectedState(Editor editor);
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
    void draw(Window window, Painter painter) {
        /// TODO: write an infinity zoom for grid

        const double depth = 1;
        const double step = 5 * depth;
        const double gridSteps = 5;
        const double border = 20;
        final double borderHeight = window.height - 1.1 * border;
        final double borderWidth = window.width - 1.5 * border;

        final centerStep = step * step * (window.zoom);

        const double panOffset = 3;
        Offset screenPan = -window.size * panOffset + (window.size * panOffset) % centerStep + window.pan % centerStep;

        for (final direction in directions) {
            double count = 0;
            for (Offset i = screenPan; count < window.width / window.zoom; i += direction * window.zoom * step) {
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
            for (Offset i = screenPan; count < window.width / window.zoom; i += direction * window.zoom * step * step) {
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
    List<bool> _hideElementsUI = [true];

    bool get _isBeamSelectionMode => _selectionMode[0];
    bool get _elementsUIVisible => _hideElementsUI[0];

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
                                        _hideElementsUI[0] = !_hideElementsUI[0];
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
                                isSelected: _hideElementsUI,
                                children: _hideElementsUI[0] ? [Icon(CadIcons.eye)] : [Icon(CadIcons.eyeOff)],
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

    String get _deltas {
        final List<double>? deltas = calc.getDeltas(widget.editor.beams);
        return deltas != null ? deltas.toString() : "";
    }

    @override
    Widget build(BuildContext context) {
        if (!widget.editor.showCalcOverlay) return SizedBox.shrink();

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
                    Text("Delta: $_deltas"),
                ],
            ),
        );
    }
}


class Calculation {
    double k(Beam beam) => beam.elasticity * beam.sectionArea / beam.length;

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

    List<double>? getDeltas(List<Beam> beams) {
        try {
            final List<Beam> newBeams = List.from(beams.reversed);
            final a = _getMatrixA(newBeams);
            final b = _getMatrixB(newBeams);
            final deltas = matrixSolve(a, b).getColumn(0);
            print(deltas);
            return deltas != null ? deltas.toList() : null;
        } catch (e) {
            return null;
        }
    }

    bool isElementsValid(List<Beam> beams) {
        if (beams.isNotEmpty) { return true; }
        for (final b in beams) {
            if (b.start.fixator != NodeFixator.disabled || b.end.fixator != NodeFixator.disabled) { return true; }
        }
        return false;
    }
}
