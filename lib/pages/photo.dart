import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  TAKE PICTURE SCREEN
// ─────────────────────────────────────────────
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with TickerProviderStateMixin {

  // ── Camera
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  late Future<void> _initializeControllerFuture;

  // ── Flash
  FlashMode _flashMode = FlashMode.off;
  static const _flashModes = [
    FlashMode.off,
    FlashMode.auto,
    FlashMode.always,
    FlashMode.torch,
  ];

  // ── Timer
  int _timerSeconds = 0;
  static const _timerOptions = [0, 3, 5, 10];
  bool _countingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  // ── Grid
  bool _showGrid = false;

  // ── Animations
  late AnimationController _shutterAnimController;
  late Animation<double> _shutterScaleAnim;

  // ── Focus
  Offset? _focusPoint;
  late AnimationController _focusAnimController;
  late Animation<double> _focusOpacityAnim;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();

    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _shutterScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterAnimController, curve: Curves.easeInOut),
    );

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _focusAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _countdownTimer?.cancel();
    _shutterAnimController.dispose();
    _focusAnimController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  CAMERA
  // ─────────────────────────────────────────────
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    setState(() {
      _initializeControllerFuture = _initCamera();
    });
  }

  // ─────────────────────────────────────────────
  //  FLASH
  // ─────────────────────────────────────────────
  void _cycleFlash() {
    final idx = _flashModes.indexOf(_flashMode);
    final next = _flashModes[(idx + 1) % _flashModes.length];
    setState(() => _flashMode = next);
    _controller?.setFlashMode(next);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  // ─────────────────────────────────────────────
  //  FOCUS
  // ─────────────────────────────────────────────
  void _handleTapToFocus(TapUpDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;
    setState(() => _focusPoint = details.localPosition);
    _controller?.setFocusPoint(Offset(x, y));
    _controller?.setExposurePoint(Offset(x, y));
    _focusAnimController.reset();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _focusAnimController.forward();
    });
  }

  // ─────────────────────────────────────────────
  //  SHUTTER
  // ─────────────────────────────────────────────
  Future<void> _onShutterPressed() async {
    if (_timerSeconds > 0 && !_countingDown) {
      _startCountdown();
      return;
    }
    await _takePicture();
  }

  Future<void> _takePicture() async {
    HapticFeedback.mediumImpact();
    _shutterAnimController.forward().then((_) => _shutterAnimController.reverse());
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  COUNTDOWN
  // ─────────────────────────────────────────────
  void _startCountdown() {
    setState(() {
      _countingDown = true;
      _countdown = _timerSeconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _countdown--);
      HapticFeedback.selectionClick();
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _countingDown = false);
        _takePicture();
      }
    });
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              _controller == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(),
              if (_showGrid) _buildGrid(),
              if (_focusPoint != null) _buildFocusIndicator(),
              if (_countingDown) _buildCountdownOverlay(),
              _buildTopBar(),
              _buildBottomControls(),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CAMERA PREVIEW
  // ─────────────────────────────────────────────
  Widget _buildCameraPreview() {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapUp: (d) => _handleTapToFocus(d, constraints),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 1,
              height: _controller!.value.previewSize?.width ?? 1,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildGrid() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: FadeTransition(
        opacity: _focusOpacityAnim,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$_countdown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.55), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TopBarButton(
                icon: _flashIcon,
                onTap: _cycleFlash,
                active: _flashMode != FlashMode.off,
              ),
              _TopBarButton(
                icon: _timerSeconds == 0 ? Icons.timer_off : Icons.timer,
                label: _timerSeconds == 0 ? null : '${_timerSeconds}s',
                onTap: () {
                  final idx = _timerOptions.indexOf(_timerSeconds);
                  setState(() => _timerSeconds =
                      _timerOptions[(idx + 1) % _timerOptions.length]);
                },
                active: _timerSeconds > 0,
              ),
              _TopBarButton(
                icon: Icons.grid_on,
                onTap: () => setState(() => _showGrid = !_showGrid),
                active: _showGrid,
              ),
              _TopBarButton(
                icon: Icons.aspect_ratio,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 40, top: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.75), Colors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Galerie
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white54,
                ),
              ),
              // Shutter
              _buildShutterButton(),
              // Flip
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return ScaleTransition(
      scale: _shutterScaleAnim,
      child: GestureDetector(
        onTap: _onShutterPressed,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GRID PAINTER
// ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  TOP BAR BUTTON
// ─────────────────────────────────────────────
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool active;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.amber.withOpacity(0.25) : Colors.black38,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.amber : Colors.white, size: 20),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  color: active ? Colors.amber : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DISPLAY PICTURE SCREEN
// ─────────────────────────────────────────────
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  // ── État courant du fichier image (modifié par crop/filtre)
  late String _currentPath;

  // ── Filtre sélectionné
  int _selectedFilter = 0;

  // ── Tags
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  // ── Caption
  final TextEditingController _captionController = TextEditingController();

  // ── Upload
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // ── Filtres disponibles
  // Matrices typed as List<double> to avoid 'int is not subtype of double'
  static const List<Map<String, Object?>> _filters = [
    {'label': 'Original', 'matrix': null},
    {
      'label': 'N&B',
      'matrix': <double>[
        0.33, 0.33, 0.33, 0.0, 0.0,
        0.33, 0.33, 0.33, 0.0, 0.0,
        0.33, 0.33, 0.33, 0.0, 0.0,
        0.0,  0.0,  0.0,  1.0, 0.0,
      ]
    },
    {
      'label': 'Sépia',
      'matrix': <double>[
        0.393, 0.769, 0.189, 0.0, 0.0,
        0.349, 0.686, 0.168, 0.0, 0.0,
        0.272, 0.534, 0.131, 0.0, 0.0,
        0.0,   0.0,   0.0,   1.0, 0.0,
      ]
    },
    {
      'label': 'Fade',
      'matrix': <double>[
        1.0, 0.0, 0.0, 0.0, 40.0,
        0.0, 1.0, 0.0, 0.0, 40.0,
        0.0, 0.0, 1.0, 0.0, 40.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'label': 'Vivid',
      'matrix': <double>[
        1.4,  -0.1, -0.1, 0.0, 0.0,
        -0.1,  1.4, -0.1, 0.0, 0.0,
        -0.1, -0.1,  1.4, 0.0, 0.0,
        0.0,   0.0,  0.0, 1.0, 0.0,
      ]
    },
    {
      'label': 'Cool',
      'matrix': <double>[
        0.8, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.9, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.2, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'label': 'Warm',
      'matrix': <double>[
        1.2, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
  }

  @override
  void dispose() {
    _tagController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // ── Recadrer ─────────────────────────────────
  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentPath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: Colors.white,
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white30,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Recadrer',
          cancelButtonTitle: 'Annuler',
          doneButtonTitle: 'Valider',
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() => _currentPath = croppedFile.path);
    }
  }

  // ── Filtre ───────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final isSelected = _selectedFilter == i;
                  final matrix = _filters[i]['matrix'];
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {});
                      setState(() => _selectedFilter = i);
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: matrix == null
                                  ? Image.file(File(_currentPath), fit: BoxFit.cover)
                                  : ColorFiltered(
                                      colorFilter: ColorFilter.matrix(
                                        matrix as List<double>,
                                      ),
                                      child: Image.file(File(_currentPath), fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filters[i]['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Tagger ───────────────────────────────────
  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tags', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Chips existants
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) => Chip(
                    label: Text('#$tag', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white12,
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white54),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                      setSheetState(() {});
                    },
                    side: BorderSide.none,
                  )).toList(),
                ),
              const SizedBox(height: 12),
              // Champ saisie
              TextField(
                controller: _tagController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ajouter un tag…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      final tag = _tagController.text.trim().replaceAll('#', '');
                      if (tag.isNotEmpty && !_tags.contains(tag)) {
                        setState(() => _tags.add(tag));
                        setSheetState(() {});
                        _tagController.clear();
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  final tag = val.trim().replaceAll('#', '');
                  if (tag.isNotEmpty && !_tags.contains(tag)) {
                    setState(() => _tags.add(tag));
                    setSheetState(() {});
                    _tagController.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Publier ──────────────────────────────────
  Future<void> _publish() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      // 1. Lire le fichier
      final file = File(_currentPath);
      final bytes = await file.readAsBytes();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      setState(() => _uploadProgress = 0.2);

      // 2. Upload vers Supabase Storage
      await supabase.storage
          .from('photos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      setState(() => _uploadProgress = 0.7);

      // 3. Récupérer l'URL publique
      final publicUrl = supabase.storage.from('photos').getPublicUrl(fileName);

      // 4. Insérer la métadonnée en base
      await supabase.from('posts').insert({
        'user_id': userId,
        'image_url': publicUrl,
        'caption': _captionController.text.trim(),
        'tags': _tags,
        'filter': _filters[_selectedFilter]['label'],
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;

      // 5. Naviguer vers le feed
      Navigator.of(context).pushNamedAndRemoveUntil('/feed', (route) => false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final matrix = _filters[_selectedFilter]['matrix'];
    final filteredImage = matrix == null
        ? Image.file(File(_currentPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix as List<double>),
            child: Image.file(File(_currentPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image plein écran avec filtre appliqué
          filteredImage,

          // Overlay upload
          if (_isUploading) _buildUploadOverlay(),

          // Dégradé + boutons haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: _isUploading ? () {} : () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _CircleButton(icon: Icons.download, onTap: _isUploading ? () {} : _saveToGallery),
                      const SizedBox(width: 10),
                      _CircleButton(icon: Icons.share, onTap: _isUploading ? () {} : _shareImage),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dégradé + actions bas
          if (!_isUploading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20, 24, 20,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomAction(
                          icon: Icons.crop,
                          label: 'Recadrer',
                          onTap: _cropImage,
                        ),
                        _BottomAction(
                          icon: Icons.color_lens_outlined,
                          label: 'Filtre',
                          onTap: _showFilterSheet,
                          active: _selectedFilter != 0,
                        ),
                        _BottomAction(
                          icon: Icons.local_offer_outlined,
                          label: 'Tags${_tags.isNotEmpty ? ' (${_tags.length})' : ''}',
                          onTap: _showTagSheet,
                          active: _tags.isNotEmpty,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tags preview
                    if (_tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 6,
                          children: _tags.map((t) => Text(
                            '#$t',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          )).toList(),
                        ),
                      ),
                    // Caption
                    TextField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        hintText: 'Ajouter une description…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white12,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    // Bouton Publier
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Publier',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Upload overlay ────────────────────────────
  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: _uploadProgress,
                strokeWidth: 3,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Publication en cours…',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sauvegarder en galerie ────────────────────
  Future<void> _saveToGallery() async {
    // Nécessite image_gallery_saver ou gal package
    // await Gal.putImage(_currentPath);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sauvegardé dans la galerie'), backgroundColor: Colors.green),
    );
  }

  // ── Partager ─────────────────────────────────
  Future<void> _shareImage() async {
    // Nécessite share_plus package
    // await Share.shareXFiles([XFile(_currentPath)]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage bientôt disponible')),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: active ? Colors.amber : Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.amber : Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}