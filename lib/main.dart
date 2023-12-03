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
    _CADEditorState() {
        input = Input(barHeight: barHeight);
    }

    Window window = Window();

    Input input = Input();
    Editor editor = Editor();

    Painter painter = Painter();
    FocusNode _focus = new FocusNode();

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

    void _pickFiles() async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();

        if (result != null) {
          PlatformFile file = result.files.first;

          print(file.name);
          print(file.bytes);
          print(file.size);
          print(file.extension);
          print(file.path);
        } else {
          // User canceled the picker
        }
    }

    @override
    Widget build(BuildContext context) {
        _pickFiles.call();
        return Row( 
            children: [
                Column(
                    children: [
                        Container(
                            width: MediaQuery.of(context).size.width - inspectorWidth,
                            height: barHeight,
                            child: editor.bar,
                        ),
                        Stack(
                            children: [
                                Container(
                                    height: MediaQuery.of(context).size.height - barHeight,
                                    child: RawKeyboardListener(
                                        autofocus: true,
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
                                                    width: MediaQuery.of(context).size.width - inspectorWidth,
                                                    height: MediaQuery.of(context).size.height,
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
                                Container(
                                    width: MediaQuery.of(context).size.width - inspectorWidth,
                                    height: barHeight,
                                    child: EditorOperationsBar(editor),
                                ),
                            ],
                        ),
                    ],
                ),
                SingleChildScrollView(
                    child: Inspector(
                        editor.selectedElements,
                        width: inspectorWidth,
                        height: MediaQuery.of(context).size.height,
                    ),
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
