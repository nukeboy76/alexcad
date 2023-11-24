import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'alexcad.dart';
import 'app_icons.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    WindowManager.instance.setMinimumSize(const Size(600, 400));
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Flutter Demo',
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
    State<CADEditor> createState() => _CADEditorState();
}

class _CADEditorState extends State<CADEditor> {
    Window window = Window();

    Input input = Input();
    UI ui = UI();
    Editor editor = Editor();
    Painter painter = Painter();
    FocusNode _focus = FocusNode();

    void init(Canvas canvas, Size size) {
        this.window.init(canvas, size);
    }

    void clip() {
        window.canvas.clipRect(Rect.fromLTWH(0, 0, window.width, window.height));
    }

    void processAll() {
        ui.render(window, painter);
        editor.processInput(input);
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
    Widget build(BuildContext context) {
        return Row( 
            children: [
                RawKeyboardListener(
                    focusNode: _focus,
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
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.height,
                                color: const Color(0xffffffff),
                                child: CustomPaint(
                                    //size: Size.infinite,
                                    painter: CADEditorRenderer(
                                        cad: this
                                    ),
                                    child: Container(
                                        alignment: Alignment.topLeft,
                                        padding: const EdgeInsets.all(5.0),
                                        child: Row(
                                            children: [
                                                editor.bar,
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
                Inspector(
                    editor.selectedElements,
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.height,
                ),
            ],
        );
    }
}


class CADEditorRenderer extends CustomPainter {
    _CADEditorState cad;
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
