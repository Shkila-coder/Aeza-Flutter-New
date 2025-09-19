import 'dart:io';
import 'dart:ui';
import 'package:aeza_flutter_new/presentation/theme/app_colors.dart';
import 'package:aeza_flutter_new/presentation/theme/app_styles.dart';
import 'package:aeza_flutter_new/presentation/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../data.repositories/firestore_repository.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

// Класс для хранения информации о точке на холсте
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

// Экран редактора
class EditorScreen extends StatefulWidget {
  // Добавляем необязательное поле для хранения начального изображения
  final String? initialBase64Image;

  const EditorScreen({
    super.key,
    this.initialBase64Image, // Добавляем его в конструктор
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Список всех точек, которые рисует пользователь. 'null' используется как разделитель между линиями.
  final List<DrawingPoint?> _points = <DrawingPoint?>[];
  // Текущий выбранный цвет.
  Color _currentColor = Colors.black;
  // Толщина кисти.
  double _brushStrokeWidth = 5.0;
  // Толщина ластика.
  double _eraserStrokeWidth = 10.0;
  // Флаг, активен ли сейчас режим ластика.
  bool isEraser = false;
  // Флаг, видима ли панель выбора толщины.
  bool _isToolbarVisible = false;


  // Фоновое изображение (если загружено).
  ui.Image? _backgroundImage;
  // Флаг, чтобы избежать повторной загрузки начального изображения.
  bool _isInitialImageLoaded = false;
  // Предустановленные цвета для палитры.
  final List<Color> _paletteColors = [
    Colors.pink.shade200, Colors.orange.shade200, Colors.yellow.shade200, Colors.green.shade200, Colors.blue.shade200, Colors.purple.shade200,
    Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple,
    Colors.red.shade900, Colors.orange.shade900, Colors.yellow.shade900, Colors.green.shade900, Colors.blue.shade900, Colors.purple.shade900,
    Colors.white, Colors.grey.shade300, Colors.grey, Colors.grey.shade700, Colors.black,
  ];

  // Глобальный ключ для доступа к виджету холста, чтобы сделать его "фотографию".
  final GlobalKey _canvasKey = GlobalKey();
  // Флаги состояний для кнопок "Сохранить" и "Поделиться".
  bool _isSaving = false;
  bool _isSharing = false;
  final FirestoreRepository _firestoreRepository = FirestoreRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // --- ОТЛАДКА ---
    developer.log('--- ЭКРАН РЕДАКТОРА: didChangeDependencies ВЫЗВАН ---');
    developer.log('widget.initialBase64Image == null ? ${widget.initialBase64Image == null}');
    developer.log('_isInitialImageLoaded = $_isInitialImageLoaded');

    if (widget.initialBase64Image != null && !_isInitialImageLoaded) {
      developer.log('Условие выполнено: вызываем _loadInitialImage()');
      _loadInitialImage();
      _isInitialImageLoaded = true;
    }
  }

  Future<void> _loadInitialImage() async {
    developer.log('--- ЭКРАН РЕДАКТОРА: _loadInitialImage НАЧАЛСЯ ---');
    try {
      final imageBytes = base64Decode(widget.initialBase64Image!);
      developer.log('Base64 успешно декодирован. Длина: ${imageBytes.length} байт');
      final image = await decodeImageFromList(imageBytes);
      developer.log('Байты успешно декодированы в картинку ui.Image. Размеры: ${image.width}x${image.height}');
      if (mounted) {
        setState(() {
          developer.log('Вызываем setState для установки _backgroundImage.');
          _backgroundImage = image;
        });
      }
    } catch (e) {
      developer.log('!!!!!! КРИТИЧЕСКАЯ ОШИБКА в _loadInitialImage: $e');
    }
  }

  Future<void> _pickImage() async {
    developer.log('--- Запрос разрешения на доступ к фото ---');
    // Запрашиваем разрешение
    final status = await Permission.photos.request();
    developer.log('ПОЛУЧЕННЫЙ СТАТУС: $status');

    // ПРОВЕРЯЕМ НЕ ТОЛЬКО ПОЛНЫЙ, НО И ОГРАНИЧЕННЫЙ ДОСТУП
    if (status.isGranted || status.isLimited) {
      developer.log('Доступ получен (полный или ограниченный). Открываем галерею...');
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final image = await decodeImageFromList(bytes);
        setState(() {
          _backgroundImage = image;
          _points.clear();
        });
      }
    } else {
      developer.log('Доступ НЕ получен. Показываем сообщение.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Для выбора изображения нужен доступ к галерее.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final String base64Image = base64Encode(pngBytes);
      await _firestoreRepository.saveDrawing(base64Image);

      await ImageGallerySaver.saveImage(pngBytes, name: "aeza_drawing_${DateTime.now().toIso8601String()}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение успешно сохранено!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    // Показываем индикатор загрузки
    setState(() => _isSharing = true);

    try {
      // 1. Получаем байты изображения с холста (точно так же, как при сохранении)
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Находим временную папку на устройстве
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/image.png').create();

      // 3. Записываем байты нашего изображения во временный файл
      await file.writeAsBytes(pngBytes);

      // 4. Вызываем нативный диалог "Поделиться" с путем к нашему файлу
      await Share.shareXFiles([XFile(file.path)], text: 'Мой рисунок из Flutter приложения!');

    } catch (e) {
      developer.log('Ошибка при экспорте: $e');
    } finally {
      // Прячем индикатор загрузки
      if(mounted) setState(() => _isSharing = false);
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey.shade900,
          title: const Text('Выберите цвет', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: _paletteColors.map((color) => _buildColorSwatch(color)).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            )
          ],
        );
      },
    );
  }

  Paint _createPaint() {
    developer.log(
        'Создание кисти: isEraser = $isEraser, '
            '_currentColor = $_currentColor, '
            'Фон есть? ${_backgroundImage != null}'
    );
    return Paint()
    // Ластик — это теперь просто белая кисть.
      ..color = isEraser ? Colors.white : _currentColor
    // Всегда используем стандартный режим наложения.
      ..blendMode = BlendMode.srcOver
      ..strokeWidth = isEraser ? _eraserStrokeWidth : _brushStrokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildToolbar(),
                if (_isToolbarVisible) _buildThicknessSlider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(21, 10, 21, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            setState(() {
                              final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                              _points.add(DrawingPoint(
                                offset: renderBox.globalToLocal(details.globalPosition),
                                paint: _createPaint(),
                              ));
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                              _points.add(DrawingPoint(
                                offset: renderBox.globalToLocal(details.globalPosition),
                                paint: _createPaint(),
                              ));
                            });
                          },
                          onPanEnd: (details) => setState(() => _points.add(null)),
                          child: CustomPaint(
                            painter: DrawingPainter(
                              points: _points,
                              backgroundImage: _backgroundImage,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildAppBar(context),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
          isEraser = false;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.appBarColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Image.asset('assets/icons/back_arrow_icon.png'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text('Новое изображение', style: AppStyles.galleryTitleStyle),
                    IconButton(
                      icon: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Image.asset('assets/icons/save_icon.png'),
                      onPressed: _isSaving ? null : _saveImage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: Image.asset('assets/icons/download_icon.png'), onPressed: _shareImage),
          IconButton(icon: Image.asset('assets/icons/image_icon.png'), onPressed: _pickImage),
          IconButton(
              icon: Image.asset('assets/icons/brush_icon.png'),
              onPressed: () => setState(() {
                isEraser = false;
                _isToolbarVisible = !_isToolbarVisible;
              })),
          IconButton(
              icon: Image.asset('assets/icons/eraser_icon.png'),
              onPressed: () => setState(() {
                isEraser = true;
                _isToolbarVisible = !_isToolbarVisible;
              })),
          IconButton(
            icon: Image.asset('assets/icons/palette_icon.png'), onPressed: _showColorPicker),
        ],
      ),
    );
  }

  Widget _buildThicknessSlider() {
    final List<double> thicknesses = [2.0, 5.0, 10.0, 15.0];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: thicknesses.map((thickness) {
          return _buildThicknessButton(thickness);
        }).toList(),
      ),
    );
  }

  Widget _buildThicknessButton(double thickness) {
    final currentActiveStrokeWidth = isEraser ? _eraserStrokeWidth : _brushStrokeWidth;
    final bool isSelected = currentActiveStrokeWidth == thickness;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isEraser) {
            _eraserStrokeWidth = thickness;
          } else {
            _brushStrokeWidth = thickness;
          }
          _isToolbarVisible = false;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGradientStart : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54),
        ),
        child: Center(
          child: Text(
            thickness.toInt().toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}


class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final ui.Image? backgroundImage;

  DrawingPainter({required this.points, this.backgroundImage});

  @override
  void paint(Canvas canvas, Size size) {
    // Шаг 1: Рисуем фон
    developer.log('--- PAINTER: метод paint ВЫЗВАН ---');
    developer.log('PAINTER: backgroundImage == null ? ${backgroundImage == null}');

    if (backgroundImage != null) {
      developer.log('PAINTER: Пытаюсь нарисовать фоновое изображение.');

      final Paint bgPaint = Paint();
      const fit = BoxFit.cover;
      final Size imageSize = Size(backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble());
      final FittedSizes fittedSizes = applyBoxFit(fit, imageSize, size);
      final Rect sourceRect = Alignment.center.inscribe(fittedSizes.source, Offset.zero & imageSize);
      final Rect destRect = Alignment.center.inscribe(fittedSizes.destination, Offset.zero & size);
      canvas.drawImageRect(backgroundImage!, sourceRect, destRect, bgPaint);
    } else {
      developer.log('PAINTER: Рисую белый фон.');
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    }

    // Шаг 2: Рисуем линии, соединяя точки
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}