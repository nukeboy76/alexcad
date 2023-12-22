import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:window_manager/window_manager.dart';

import 'cad_icons.dart';
import 'editor.dart';
import 'input.dart';
import 'inspector.dart';
import 'painter.dart';
import 'window.dart';


void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    //await windowManager.ensureInitialized();
    //WindowManager.instance.setMinimumSize(const Size(600, 400));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    runApp(const MyApp());
}


class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'alexcad',
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
            ),
            home: new Scaffold(
                body: const CADEditor(),
            ),
        );
    }
}


class CADEditor extends StatefulWidget {
    const CADEditor({super.key});

    @override
    State<CADEditor> createState() => CADEditorState();
}


class CADEditorState extends State<CADEditor> {
    CADEditorState() {
        input = Input(barHeight: barHeight);
    }

    Window window = Window();

    Input input = Input();
    Editor editor = Editor();

    Painter painter = Painter();

    double get inspectorWidth => 300;
    double get barHeight => 60;

    void init(Canvas canvas, Size size) {
        this.window.init(canvas, size);
    }

    void clip() {
        window.canvas.clipRect(Rect.fromLTWH(0, 0, window.width, window.height));
    }

    void processAll() {
        editor.processInput(window, input);
        editor.render(window, painter, input);
    }

    void _handlePointerMove(PointerEvent event) {
        setState(() {
            input.handlePointerMove(window, event);
        });
    }

    void _handlePointerUp(PointerEvent event) {
        setState(() {
            input.handlePointerUp(window, event);
        });
    }

    void _handlePointerDown(PointerEvent event) {
        setState(() {
            input.handlePointerDown(window, event);
        });
    }

    void _handlePointerScroll(PointerScrollEvent event) {
        setState(() {
            input.handlePointerScroll(window, event);
        });
    }

    void _handleKeyEvent(RawKeyEvent event) {
        setState(() {
            input.handleKeyEvent(event);
        });
    }


    @override
    void initState() {
       SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
       super.initState();
    } 

    @override
    Widget build(BuildContext context) {
        final height = (MediaQuery.of(context).size.height).clamp(0.0, double.infinity);
        final editorHeight = (MediaQuery.of(context).size.height - barHeight).clamp(0.0, double.infinity);
        final editorWidth = (MediaQuery.of(context).size.width - inspectorWidth).clamp(0.0, double.infinity);
        return Row( 
            children: [
                Column(
                    children: [
                        EditorBar(
                            editor,
                            height: barHeight,
                            width: editorWidth,
                        ),
                        Stack(
                            children: [
                                Container(
                                    height: editorHeight,
                                    child: RawKeyboardListener(
                                        autofocus: true,
                                        focusNode: editor.focus,
                                        onKey: _handleKeyEvent,
                                        child: MouseRegion(
                                            onHover: _handlePointerMove,
                                            child: Listener(
                                                onPointerUp: _handlePointerUp,
                                                onPointerDown: _handlePointerDown,
                                                onPointerMove: _handlePointerMove,
                                                onPointerSignal: (pointerSignal) { 
                                                    if(pointerSignal is PointerScrollEvent) {
                                                            _handlePointerScroll(pointerSignal);
                                                    }
                                                },
                                                child: Container(
                                                    width: editorWidth,
                                                    height: height,
                                                    color: Colors.white,
                                                    child: CustomPaint(
                                                        //size: Size.infinite,
                                                        painter: CADEditorRenderer(
                                                            cad: this
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                                EditorOperationsBar(
                                    editor,
                                    window,
                                    width: editorWidth,
                                    height: barHeight,
                                ),
                                FileOperationsBar(
                                    editor,
                                    width: editorWidth,
                                    height: editorHeight,
                                ),
                            ],
                        ),
                    ],
                ),
                Inspector(
                    editor.selectedElements,
                    width: inspectorWidth,
                    height: height,
                ),
            ],
        );
    }
}

class CADEditorRenderer extends CustomPainter {
    CADEditorState cad;
    CADEditorRenderer({required this.cad});

    @override
    void paint(Canvas canvas, Size size) {
        cad.init(canvas, size);
        cad.clip();
        cad.processAll();
    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class FileOperationsBar extends StatefulWidget {
    FileOperationsBar(
        this.editor, {
        required this.width,
        required this.height,
    });

    final Editor editor;
    final double width;
    final double height;

    @override
    State<FileOperationsBar> createState() => _FileOperationsBarState();
}

class _FileOperationsBarState extends State<FileOperationsBar> {
    @override
    Widget build(BuildContext context) {
        if (!widget.editor.showCalcOverlay) return SizedBox.shrink();
        return Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.centerLeft,
            color: Colors.white,
            child: Row(
                children: [
                    //TODO
                ],
            ),
        );
    }
}