import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icons.dart';
import 'editor.dart';
import 'input.dart';
import 'painter.dart';
import 'window.dart';
import 'utils/utils.dart';


const String defaultTextInputRegExpTemplate = '[0-9\.\-]';


class Inspector extends StatefulWidget {
    Inspector(this.selectedElements, {
        super.key,
        this.width = 400,
        this.height = 1080,
        this.color = const Color.fromRGBO(73, 162, 255, 128), 
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
    int get selectedElementsLength => widget.selectedElements.length;
    bool get selectedElementsEmpty => widget.selectedElements.isEmpty;
    bool get selectedIsBeam => widget.selectedElements[0] is Beam;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: widget.width,
            height: widget.height,
            color: widget.color,
            child: ListView(
                children: [
                    Text("${widget.title}"),
                    selectedElementsLength != 1 ? Row() : selectedIsBeam ?
                        BeamWidget(
                            beam: widget.selectedElements[0],
                        ) : NodeWidget(
                            node: widget.selectedElements[0],
                        ),
                ],
            ),
        );
    }
}


class BeamWidget extends StatefulWidget {
    BeamWidget({
        super.key,
        required this.beam,
        this.title = "Beam",
    });

    Beam beam;
    String title;

    final sectionValues = BeamSection.values.map((e) => DropdownMenuItem(
        child: Text(e.name),
        value: e.name,
    )).toList();

    @override
    State<BeamWidget> createState() => _BeamWidgetState();
}


class _BeamWidgetState extends State<BeamWidget> {
    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(widget.title),
                NodeWidget(
                    title: "Start node",
                    node: widget.beam.start,
                ),
                NodeWidget(
                    title: "End node",
                    node: widget.beam.end,
                ),
                OffsetWidget(
                    onChange: (value) {
                        setState(() {
                            widget.beam.force = value;
                        });
                    },
                    offset: widget.beam.force,
                    title: "Force",
                    labelX: "Fx",
                    labelY: "Fy",
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.beam.width = value;
                        });
                    },
                    value: widget.beam.width,
                    title: "Width",
                    label: "F",
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.beam.sectionArea = value;
                        });
                    },
                    value: widget.beam.sectionArea,
                    title: "Section area",
                    label: "Area",
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.beam.elasticity = value;
                        });
                    },
                    value: widget.beam.elasticity,
                    title: "Elasticity",
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.beam.tension = value;
                        });
                    },
                    value: widget.beam.tension,
                    title: "Tension",
                ),
            ],
        );
    }
}


class NodeWidget extends StatefulWidget {
    NodeWidget({
        super.key,
        required this.node,
        this.title = "Node",
    });

    String title;
    Node node;

    @override
    State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                OffsetWidget(
                    onChange: (value) {
                        setState(() {
                            widget.node.position = value;
                        });
                    },
                    offset: widget.node.position,
                    title: "Position",
                    labelX: "X",
                    labelY: "Y",
                ),
                OffsetWidget(
                    onChange: (value) {
                        setState(() {
                            widget.node.force = value;
                        });
                    },
                    offset: widget.node.force,
                    title: "Force",
                    labelX: "Fx",
                    labelY: "Fy",
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.node.torqueForce = value;
                        });
                    },
                    value: widget.node.torqueForce,
                    title: "Torque force",
                    label: "F",
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Flexible(
                            child: Text(
                                "Node fixator",
                            ),
                        ),
                        Flexible(
                            child: Text(
                                widget.node.fixator.toString(),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}


class OffsetWidget extends StatelessWidget {
    OffsetWidget({
        super.key,
        required this.onChange,
        required this.offset,
        this.title = "Offset",
        this.labelX = "",
        this.labelY = "",
    });

    final onChange;
    final offset;
    String title;
    String labelX;
    String labelY;
    TextInputFormatter formatterX = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));
    TextInputFormatter formatterY = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));

    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Flexible(
                            child: Text(
                                title,
                            ),
                        ),
                        Flexible(
                            child: TextField(
                                controller: TextEditingController(text: offset.dx.toStringAsFixed(6)),
                                decoration: InputDecoration(labelText: labelX),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    formatterX,
                                ],
                                onSubmitted: (value) => onChange(Offset(double.parse(value), offset.dy)),
                            ),
                        ),
                        Flexible(
                            child: TextField(
                                controller: TextEditingController(text: offset.dy.toStringAsFixed(6)),
                                decoration: InputDecoration(labelText: labelY),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    formatterY,
                                ],
                                onSubmitted: (value) => onChange(Offset(offset.dx, double.parse(value))),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}


class SingleValueWidget extends StatelessWidget {
    SingleValueWidget({
        super.key,
        required this.onChange,
        required this.value,
        this.title = "Value",
        this.label = "",
    });

    final onChange;
    final value;
    String title;
    String label;
    TextInputFormatter formatter = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));

    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Flexible(
                            child: Text(
                                title,
                            ),
                        ),
                        Flexible(
                            child: TextField(
                                controller: TextEditingController(text: value.toStringAsFixed(6)),
                                decoration: InputDecoration(labelText: label),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    formatter,
                                ],
                                onSubmitted: (value) => onChange(double.parse(value)),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}
