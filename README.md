# **Optical Character Recognition TFLite Flutter**

1. Copy your ```.tflite``` model to the ```assets``` folder

1. Add the model path to ```pubspec.yaml``` file
```yaml
    .
    .
    .
    flutter:
        uses-material-design: true

        assets:
            - assets/MODEL_NAME.tflite
    .
    .
    .
```

1. Replace the assets path String in ```lib/pages/drawing_pad.dart```
```dart
    class _DrawingPadState extends State<DrawingPad> {
        .
        .
        .
        List<String> modelPaths = [
            'assets/MODEL_NAME_1.tflite', 
            'assets/MODEL_NAME_2.tflite'
            ];
        .
        .
        .
    }
```
