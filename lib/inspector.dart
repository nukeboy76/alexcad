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
import 'utils/colors.dart';
import 'window.dart';


const String defaultTextInputRegExpTemplate = '[+-]?\\d*\\.?\\d+';
const String positiveTextInputRegExpTemplate = '[+]?\\d*\\.?\\d+';


class Inspector extends StatefulWidget {
    Inspector(this.selectedElements, {
        super.key,
        this.width = 400,
        this.height = 1080,
        this.title = "Inspector",
        this.child,
        required this.visible,
        required this.update,
    });

    final Color color = purpleColor.lighter(0.9);
    final List<dynamic> selectedElements;
    final double width;
    final double height;
    final String title;
    final Widget? child;
    final bool visible;
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
                    padding: const EdgeInsets.all(4),
                    children: [
                        Container(
                            alignment: Alignment.center,
                            height: 46.666,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: purpleColor.lighter(0.8),
                                border: Border.all(
                                    color: purpleColor.lighter(0.7),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: purpleColor.darker(0.5),
                                ),
                            ),
                        ),
                        !widget.visible ? Text(
                            "You are in the calculation view mode",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: pinkColor.darker(0.25),
                            ),
                        ) : SizedBox.shrink(),
                        !widget.visible || selectedElementsLength != 1 ? Row() : selectedIsBeam ?
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
        this.title = "[Beam]",
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
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: purpleColor.lighter(0.7),
                        border: Border.all(
                            color: purpleColor.lighter(0.6),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: purpleColor.darker(0.5),
                        ), 
                    ),
                ),
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
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: purpleColor.lighter(0.8),
                        border: Border.all(
                            color: purpleColor.lighter(0.7),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                        "Beam parameters",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: purpleColor.darker(0.5),
                        ),
                    ),
                ),
                Container(
                    padding: const EdgeInsets.all(2),
                    margin: const EdgeInsets.all(2),
                    child: Row(
                        children: [
                            Text(
                                "Length",
                                style: TextStyle(
                                    color: purpleColor.darker(0.5),
                                ),
                            ),
                            Spacer(),
                            Text(
                                "${widget.beam.length}",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: purpleColor.darker(0.5),
                                ),
                            )
                        ]
                    ),
                ),
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
                SingleValueWidget(
                    onChange: (value) {
                        setState(() {
                            widget.onChange();
                            widget.beam.sectionArea = value;
                        });
                    },
                    value: widget.beam.sectionArea,
                    title: "Section area",
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
        this.title = "[Node]",
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
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: widget.title == "[Node]" ? purpleColor.lighter(0.7) : purpleColor.lighter(0.8),
                        border: Border.all(color: widget.title == "[Node]" ? purpleColor.lighter(0.6) : purpleColor.lighter(0.7)),
                        borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                    child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: purpleColor.darker(0.5),
                        ),
                    ),
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
                    title: "Force     ",
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
                Container(
                    padding: const EdgeInsets.all(2),
                    margin: const EdgeInsets.all(2),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Text(
                                    "Node fixator",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: purpleColor.darker(0.5),
                                    ),
                                ),
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
                                    dropdownMenuEntries: NodeFixator.values.map<DropdownMenuEntry<NodeFixator>>(
                                        (NodeFixator nodeFixator) {
                                        return DropdownMenuEntry<NodeFixator>(
                                            value: nodeFixator,
                                            label: nodeFixator.name,
                                            enabled: true,
                                            style: MenuItemButton.styleFrom(
                                                foregroundColor: purpleColor.darker(0.5),
                                            ),
                                        );
                                    }).toList(),
                                ),
                            ),
                        ],
                    ),
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
        _controllerX = TextEditingController(text: offset.dx.toString()),
        _controllerY = TextEditingController(text: offset.dy.toString());

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
        return Container(
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.all(2),
            alignment: Alignment.bottomCenter,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: Column(
                                    children: [
                                        SizedBox(height: 16.5),
                                        Text(
                                            widget.title,
                                            style: TextStyle(
                                                color: purpleColor.darker(0.5),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            Flexible(
                                child: TextField(
                                    textAlign: TextAlign.justify,
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
            ),
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
    _SingleValueWidgetState(dynamic value) : _controller = TextEditingController(text: value.toString());

    TextEditingController _controller;

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.all(2),
            height: 66,
            alignment: Alignment.center,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Flexible(
                        child: Column(
                            children: [
                                SizedBox(height: 28),
                                Text(
                                    widget.title,
                                    style: TextStyle(
                                        color: purpleColor.darker(0.5),
                                    ),
                                ),
                            ],
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
                                    //print(double.parse(value));
                                    widget.onChange(double.parse(value));
                                });
                            },
                        ),
                    ),
                ],
            ),
        );
    }
}
