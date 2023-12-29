import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cad_icons.dart';
import 'cad_colors.dart';
import 'editor.dart';
import 'input.dart';
import 'painter.dart';
import 'types.dart';
import 'utils/utils.dart';
import 'window.dart';


const String defaultTextInputRegExpTemplate = '[0-9\.\-]';
const String positiveTextInputRegExpTemplate = '[0-9\.]';


//abstract class InspectorView {
//    Widget get widget;
//}


//class NodeInspectorView extends InspectorView {
//    NodeInspectorView(this.element);

//    final element;

//    Widget get widget => NodeWidget(
//        onChange: (value) {},
//        node: element,
//    );
//}


//class BeamInspectorView extends InspectorView {
//    BeamInspectorView(this.element);

//    final element;

//    Widget get widget => BeamWidget(beam: element, );
//}


class Inspector extends StatefulWidget {
    Inspector(this.selectedElements, {
        super.key,
        this.width = 400,
        this.height = 1080,
        this.title = "Inspector",
        this.child,
        required this.update,
    });

    final Color color = purpleColor.lighter(0.9);
    final List<dynamic> selectedElements;
    final double width;
    final double height;
    final String title;
    final Widget? child;
    final update;

    @override
    State<Inspector> createState() => _InspectorState();
}


class _InspectorState extends State<Inspector> {
    int get selectedElementsLength => widget.selectedElements.length;
    bool get selectedElementsEmpty => widget.selectedElements.isEmpty;
    bool get selectedIsBeam => widget.selectedElements[0] is Beam;

    @override
    Widget build(BuildContext context) {
        return SingleChildScrollView(
            child: Container(
                width: widget.width,
                height: widget.height,
                color: widget.color,
                child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                        Text(
                            widget.title,
                            textAlign: TextAlign.center,
                        ),
                        selectedElementsLength != 1 ? Row() : selectedIsBeam ?
                            BeamWidget(
                                beam: widget.selectedElements[0],
                                onChange: () { 
                                    setState(() {
                                        widget.update();
                                    });
                                },
                            ) : NodeWidget(
                                node: widget.selectedElements[0],
                                onChange: () {
                                    setState(() {
                                        widget.update();
                                    });
                                },
                            ),
                    ],
                ),
            ),
        );
    }
}


class BeamWidget extends StatefulWidget {
    BeamWidget({
        super.key,
        required this.beam,
        this.title = "Beam",
        required this.onChange,
    });

    Beam beam;
    String title;
    final onChange;

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
                    onChange: () {
                        setState(() {
                            widget.onChange();
                        });
                    },
                    title: "Start node",
                    node: widget.beam.start,
                ),
                NodeWidget(
                    onChange: () {
                        setState(() {
                            widget.onChange();
                        });
                    },
                    title: "End node",
                    node: widget.beam.end,
                ),
                Text("Beam parameters"),
                OffsetWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
                            widget.beam.force = value;
                        });
                    },
                    offset: widget.beam.force,
                    title: "Force",
                    labelX: "Fx",
                    labelY: "Fy",
                ),
                Row(
                    children: [
                        Text("Length"),
                        Spacer(),
                        Text("${widget.beam.length}")
                    ]
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
                            widget.beam.sectionArea = value;
                        });
                    },
                    value: widget.beam.sectionArea,
                    title: "Section area",
                    label: "Area",
                    overrideFormatter: FilteringTextInputFormatter.allow(RegExp(positiveTextInputRegExpTemplate)),
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
                            widget.beam.elasticity = value;
                        });
                    },
                    value: widget.beam.elasticity,
                    title: "Elasticity",
                    overrideFormatter: FilteringTextInputFormatter.allow(RegExp(positiveTextInputRegExpTemplate)),
                ),
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
                            widget.beam.tension = value;
                        });
                    },
                    value: widget.beam.tension,
                    title: "Tension",
                    overrideFormatter: FilteringTextInputFormatter.allow(RegExp(positiveTextInputRegExpTemplate)),
                ),
            ],
        );
    }
}


class NodeWidget extends StatefulWidget {
    NodeWidget({
        super.key,
        required this.onChange,
        required this.node,
        this.title = "Node",
    });

    final onChange;
    String title;
    Node node;

    @override
    State<NodeWidget> createState() => _NodeWidgetState();
}


class _NodeWidgetState extends State<NodeWidget> {
    TextEditingController _fixatorController = TextEditingController();

    @override
    void dispose() {
        _fixatorController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                    widget.title,
                    textAlign: TextAlign.center,
                ),
                OffsetWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
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
                            widget.onChange();
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
                            widget.onChange();
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
                            child: Text("Node fixator"),
                        ),
                        Flexible(
                            child: DropdownMenu<NodeFixator>(
                                initialSelection: widget.node.fixator,
                                controller: _fixatorController,
                                requestFocusOnTap: false,
                                onSelected: (value) {
                                    setState(() {
                                        widget.onChange();
                                        widget.node.fixator = value!;
                                    });
                                },
                                dropdownMenuEntries: NodeFixator.values
                                        .map<DropdownMenuEntry<NodeFixator>>(
                                                (NodeFixator nodeFixator) {
                                    return DropdownMenuEntry<NodeFixator>(
                                        value: nodeFixator,
                                        label: nodeFixator.name,
                                        enabled: true,
                                        style: MenuItemButton.styleFrom(
                                            foregroundColor: cianColor.darker(0.5),
                                        ),
                                    );
                                }).toList(),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}


class OffsetWidget extends StatefulWidget {
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

    @override
    State<OffsetWidget> createState() => _OffsetWidgetState(this.offset);
}


class _OffsetWidgetState extends State<OffsetWidget> {
    _OffsetWidgetState(Offset offset) : 
        _controllerX = TextEditingController(text: offset.dx.toStringAsFixed(6)),
        _controllerY = TextEditingController(text: offset.dy.toStringAsFixed(6));

    TextInputFormatter formatterX = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));
    TextInputFormatter formatterY = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));

    TextEditingController _controllerX;
    TextEditingController _controllerY;

    @override
    void dispose() {
        _controllerX.dispose();
        _controllerY.dispose();
        super.dispose();
    }

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
                                widget.title,
                            ),
                        ),
                        Flexible(
                            child: TextField(
                                controller: _controllerX,
                                decoration: InputDecoration(labelText: widget.labelX),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    formatterX,
                                ],
                                onChanged: (value) {
                                    setState(() {
                                        widget.onChange(Offset(double.parse(value), widget.offset.dy));
                                    });
                                }
                            ),
                        ),
                        Flexible(
                            child: TextField(
                                controller: _controllerY,
                                decoration: InputDecoration(labelText: widget.labelY),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    formatterY,
                                ],
                                onChanged: (value) {
                                    setState(() { 
                                        widget.onChange(Offset(widget.offset.dx, double.parse(value)));
                                    });
                                },
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}


class SingleValueWidget extends StatefulWidget {
    SingleValueWidget({
        super.key,
        required this.onChange,
        required this.value,
        this.title = "Value",
        this.label = "",
        TextInputFormatter? overrideFormatter,
    }) {
        if (overrideFormatter != null) {
            formatter = overrideFormatter;
        }
    }

    final onChange;
    final value;
    String title;
    String label;
    TextInputFormatter formatter = FilteringTextInputFormatter.allow(RegExp(defaultTextInputRegExpTemplate));

    @override
    State<SingleValueWidget> createState() => _SingleValueWidgetState(value);
}


class _SingleValueWidgetState extends State<SingleValueWidget> {
    _SingleValueWidgetState(dynamic value) : _controller = TextEditingController(text: value.toStringAsFixed(6));

    TextEditingController _controller;

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

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
                                widget.title,
                            ),
                        ),
                        Flexible(
                            child: TextFormField(
                                autofocus: true,
                                controller: _controller,
                                decoration: InputDecoration(labelText: widget.label),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                    widget.formatter,
                                ],
                                onChanged: (value) {
                                    setState(() {
                                        print(double.parse(value));
                                        widget.onChange(double.parse(value));
                                    });
                                },
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}
