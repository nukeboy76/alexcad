import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:window_manager/window_manager.dart';

import 'cad_colors.dart';
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
    runApp(const App());
}


class App extends StatelessWidget {
    const App({super.key});

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
                body: const AppWidget(),
            ),
        );
    }
}


class AppWidget extends StatefulWidget {
    const AppWidget({super.key});

    @override
    State<AppWidget> createState() => AppWidgetState();
}


class AppWidgetState extends State<AppWidget> {
    AppWidgetState() {
        input = Input(barHeight: barHeight + fileOperationsBarHeight);
    }

    static const double inspectorWidth = 300;
    static const double barHeight = 60;
    static const double fileOperationsBarHeight = 40;

    Window window = Window();
    Input input = Input();
    Editor editor = Editor();
    Painter painter = Painter();

    bool showCalcOverlay = false;

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

    int inc = 0;

    @override
    Widget build(BuildContext context) {
        final double height = MediaQuery.of(context).size.height;
        final double width = MediaQuery.of(context).size.width;
        final double editorHeight = (MediaQuery.of(context).size.height - barHeight - fileOperationsBarHeight).clamp(0.0, double.infinity);
        final double editorWidth = (MediaQuery.of(context).size.width - inspectorWidth).clamp(0.0, double.infinity);

        return Container(
            height: height,
            width: width,
            child: Column(
                children: [
                    FileOperationsBar(
                        editor,
                        height: fileOperationsBarHeight,
                    ),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Column(
                                children: [
                                    EditorBar(
                                        editor,
                                        width: editorWidth,
                                        height: barHeight,
                                        onChange: (value) {
                                            setState(() {
                                                showCalcOverlay = value;
                                            });
                                        },
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
                                                                    painter: AppWidgetRenderer(
                                                                        cad: this,
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
                                            CalculationOverlay(
                                                editor,
                                                width: editorWidth,
                                                height: editorHeight,
                                                visible: showCalcOverlay,
                                                close: () {
                                                    setState(() {
                                                        showCalcOverlay = false;
                                                    });
                                                },
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            Inspector(
                                editor.selectedElements,
                                width: inspectorWidth,
                                height: height - fileOperationsBarHeight,
                                update: () {
                                    setState(() {});
                                },
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}


class AppWidgetRenderer extends CustomPainter {
    AppWidgetRenderer({required this.cad});
    AppWidgetState cad;

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
        this.width,
        this.height,
    });

    Editor editor;
    final double? width;
    final double? height;

    @override
    State<FileOperationsBar> createState() => _FileOperationsBarState();
}

class _FileOperationsBarState extends State<FileOperationsBar> {
    static const double widgetScale = 1;
    static const double fontSize = 16 * widgetScale;
    static const double edgeInsets = 12.0 * widgetScale;
    static const double spaceBetween = 8 * widgetScale;
    static const double spaceRight = 4.5;
    static const double roundness = 5;
    static const double colorScale = 0.1;
    static const String defaultName = 'cad_data.json';

    String? openFilePath;

    String _editorDataToJson() {
        String nodesToJson = jsonEncode(widget.editor.nodes);
        String beamsToJson = jsonEncode(widget.editor.beams);

        String jsonEditorData = "{\"nodes\":$nodesToJson,\"beams\":$beamsToJson}";
        return jsonEditorData;
    }

    void _jsonToEditor(dynamic json) {
        widget.editor.clearAllElements();
        json = jsonDecode(json);

        var nodesJson = json['nodes'] as List;
        List<Node> newNodes = nodesJson.map((node) => Node.fromJson(node)).toList();
        var beamsJson = json['beams'] as List;
        List<Beam> newBeams = beamsJson.map((beam) => Beam.fromJson(beam, newNodes)).toList();

        final List<EditorElement> newElements = List.from(newBeams)..addAll(newNodes);
        widget.editor.elements = newElements;
    }

    void _readEditorData() async {
        try {
            FilePickerResult? result = await FilePicker.platform.pickFiles();

            if (result != null) {
                openFilePath = result.files.single.path;
                print(openFilePath);
                File file = File(openFilePath!);
                final content = await file.readAsString();

                _jsonToEditor(content);
            } else {
                // User canceled the picker
            }
        } catch (e) {
            print(e);
        }
    }

    void _writeEditorData() async {
        if (openFilePath != null) {
            final file = File(openFilePath!);
            final data = _editorDataToJson();
            print(data);
            file.writeAsString(data);
        } else {
            _writeEditorDataToPath.call();
        }
    }

    void _writeEditorDataToPath() async {
        String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: openFilePath != null ? openFilePath : defaultName,
            lockParentWindow: true,
        );

        try {
            if (outputFile != null) {
                openFilePath = outputFile;

                final file = File(openFilePath!);
                file.writeAsString(_editorDataToJson());

            } else {
              // User canceled the picker
            }
        } catch (e) {
            print(e);
        }
    }

    void _openFile() {
        _readEditorData.call();
    }

    void _saveFile() {
        _writeEditorData.call();
    }

    void _saveFileAs() {
        _writeEditorDataToPath.call();
    }

    void _startNew() {
        widget.editor.clearAllElements();
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.centerLeft,
            color: purpleColor.lighter(0.8),
            child: Row(
                children: [
                    SizedBox(width: spaceRight),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: pinkColor.lighter(colorScale),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(edgeInsets),
                            textStyle: const TextStyle(fontSize: fontSize),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(roundness),
                            ),
                        ),
                        onPressed: () {
                            setState(() {
                                _openFile();
                            });
                        },
                        child: const Text('Open'),
                    ),
                    SizedBox(width: spaceBetween),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: purpleColor.lighter(colorScale),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(edgeInsets),
                            textStyle: const TextStyle(fontSize: fontSize),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(roundness),
                            ),
                        ),
                        onPressed: () {
                            setState(() {
                                _saveFile();
                            });
                        },
                        child: const Text('Save'),
                    ),
                    SizedBox(width: spaceBetween),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: purpleColor.lighter(colorScale),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(edgeInsets),
                            textStyle: const TextStyle(fontSize: fontSize),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(roundness),
                            ),
                        ),
                        onPressed: () {
                            setState(() {
                                _saveFileAs();
                            });
                        },
                        child: const Text('Save as'),
                    ),
                    SizedBox(width: spaceBetween * 3),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: cianColor.darker(0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(edgeInsets),
                            textStyle: const TextStyle(fontSize: fontSize),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(roundness),
                            ),
                        ),
                        onPressed: () {
                            setState(() {
                                _startNew();
                            });
                        },
                        child: const Text('New'),
                    ),
                ],
            ),
        );
    }
}