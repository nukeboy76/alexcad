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

/*
class InspectorNode extends StatefulWidget {
    const InspectorNode({
        super.key,
    });

    List<EditorElement> selectedElements;

    @override
    State<Inspector> createState() => _InspectorNodeState();
}

class _InspectorNodeState extends State<InspectorNode> {
    @override
    Widget build(BuildContext context) {

    }
}
*/
