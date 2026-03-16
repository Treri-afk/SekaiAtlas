import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/features/AventureNotifier.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────
//  TAKE PICTURE SCREEN  (inchangé)
// ─────────────────────────────────────────────
class TakePictureScreen extends StatefulWidget {
  final VoidCallback? onAdventureCreated;
  final void Function(VoidCallback)? onRegisterRecheck;
  const TakePictureScreen({super.key, this.onAdventureCreated, this.onRegisterRecheck});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with TickerProviderStateMixin {

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  late Future<void> _initializeControllerFuture;

  FlashMode _flashMode = FlashMode.off;
  static const _flashModes = [
    FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch,
  ];

  int _timerSeconds = 0;
  static const _timerOptions = [0, 3, 5, 10];
  bool _countingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  bool _showGrid = false;

  Map<String, dynamic>? _currentAdventure;
  bool _checkingAdventure = true;
  List<dynamic>? _friends;
  int? _currentUserId;

  late AnimationController _shutterAnimController;
  late Animation<double> _shutterScaleAnim;

  Offset? _focusPoint;
  late AnimationController _focusAnimController;
  late Animation<double> _focusOpacityAnim;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
    AdventureNotifier.instance.addListener(_checkAdventure);
    _checkAdventure();
    widget.onRegisterRecheck?.call(_checkAdventure);
    _requestLocationPermission();

    _shutterAnimController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
    );
    _shutterScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterAnimController, curve: Curves.easeInOut),
    );
    _focusAnimController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300),
    );
    _focusOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _focusAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    AdventureNotifier.instance.removeListener(_checkAdventure);
    _controller?.dispose();
    _countdownTimer?.cancel();
    _shutterAnimController.dispose();
    _focusAnimController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    debugPrint('📍 [GPS] _requestLocationPermission — start');
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      debugPrint('📍 [GPS] permission actuelle : $perm');
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        debugPrint('📍 [GPS] permission après demande : $perm');
      }
      if (perm == LocationPermission.deniedForever) {
        debugPrint('🔴 [GPS] permission refusée définitivement');
      }
    } catch (e) {
      debugPrint('🔴 [GPS] erreur permission : $e');
    }
  }

  Future<void> _checkAdventure() async {
    debugPrint('🟦 [camera] _checkAdventure — start');
    try {
      final pid = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('🟦 [camera] pid = $pid');
      if (pid == null) { setState(() => _checkingAdventure = false); return; }

      final u = await fetchUserByProviderId(pid);
      debugPrint('🟦 [camera] user = id=${u["id"]} username=${u["username"]}');

      final results = await Future.wait([
        adventureRunning(u["id"]),
        fetchFriends(u["id"]),
      ]);
      final d = results[0] as List<dynamic>;
      final f = results[1] as List<dynamic>;
      debugPrint('🟦 [camera] adventureRunning réponse: $d');
      debugPrint('🟦 [camera] friends count: ${f.length}');

      if (!mounted) return;
      setState(() {
        _currentUserId    = u["id"] as int?;
        _currentAdventure = d.isNotEmpty
            ? Map<String, dynamic>.from(d[0]["result"]["adventure"] as Map)
            : null;
        _friends          = f;
        _checkingAdventure = false;
      });
      debugPrint('🟦 [camera] _currentAdventure = $_currentAdventure');
      debugPrint('🟦 [camera] _currentUserId = $_currentUserId');
    } catch (e) {
      debugPrint('🔴 [camera] _checkAdventure error: $e');
      if (!mounted) return;
      setState(() => _checkingAdventure = false);
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    _controller = CameraController(_cameras[_selectedCameraIndex], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    setState(() { _initializeControllerFuture = _initCamera(); });
  }

  Future<void> _openGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DisplayPictureScreen(
        imagePath:   picked.path,
        adventureId: _currentAdventure?["id"] as int?,
        userId:      _currentUserId,
      )),
    );
  }

  void _cycleFlash() {
    final next = _flashModes[(_flashModes.indexOf(_flashMode) + 1) % _flashModes.length];
    setState(() => _flashMode = next);
    _controller?.setFlashMode(next);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:    return Icons.flash_off;
      case FlashMode.auto:   return Icons.flash_auto;
      case FlashMode.always: return Icons.flash_on;
      case FlashMode.torch:  return Icons.highlight;
    }
  }

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

  Future<void> _onShutterPressed() async {
    if (_timerSeconds > 0 && !_countingDown) { _startCountdown(); return; }
    await _takePicture();
  }

  Future<void> _takePicture() async {
    HapticFeedback.mediumImpact();
    _shutterAnimController.forward().then((_) => _shutterAnimController.reverse());
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      debugPrint('📸 [camera] photo prise : ${image.path}');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DisplayPictureScreen(
          imagePath:   image.path,
          adventureId: _currentAdventure?["id"] as int?,
          userId:      _currentUserId,
        )),
      );
    } catch (e) {
      debugPrint('🔴 [camera] _takePicture error: $e');
    }
  }

  void _startCountdown() {
    setState(() { _countingDown = true; _countdown = _timerSeconds; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || _controller == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final hasAdventure = !_checkingAdventure && _currentAdventure != null;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildPreview(),
              if (_showGrid) _buildGrid(),
              if (_focusPoint != null) _buildFocusIndicator(),
              if (_countingDown) _buildCountdown(),
              _buildTopBar(),
              _buildBottomControls(),
              if (_checkingAdventure || !hasAdventure)
                _buildNoAdventureOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoAdventureOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_checkingAdventure)
                    const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  else ...[
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aucune aventure en cours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rejoins ou crée une aventure pour pouvoir prendre des photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => CommencerUneNouvelleAventureForm.show(
                        context,
                        users: _friends,
                        onSuccess: () {
                          _checkAdventure();
                          widget.onAdventureCreated?.call();
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kPrimary, kPrimaryLt]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Rejoindre une aventure',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapUp: (d) => _handleTapToFocus(d, constraints),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width:  _controller!.value.previewSize?.height ?? 1,
              height: _controller!.value.previewSize?.width  ?? 1,
              child:  CameraPreview(_controller!),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildGrid() => IgnorePointer(
    child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
  );

  Widget _buildFocusIndicator() => Positioned(
    left: _focusPoint!.dx - 30, top: _focusPoint!.dy - 30,
    child: FadeTransition(
      opacity: _focusOpacityAnim,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(border: Border.all(color: kPrimary, width: 1.5)),
      ),
    ),
  );

  Widget _buildCountdown() => Center(
    child: Container(
      width: 120, height: 120,
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Center(
        child: Text('$_countdown',
          style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
      ),
    ),
  );

  Widget _buildTopBar() => Positioned(
    top: 0, left: 0, right: 0,
    child: SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.55), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TopBarBtn(icon: _flashIcon, onTap: _cycleFlash, active: _flashMode != FlashMode.off),
            _TopBarBtn(
              icon: _timerSeconds == 0 ? Icons.timer_off : Icons.timer,
              label: _timerSeconds == 0 ? null : '${_timerSeconds}s',
              onTap: () {
                final idx = _timerOptions.indexOf(_timerSeconds);
                setState(() => _timerSeconds = _timerOptions[(idx + 1) % _timerOptions.length]);
              },
              active: _timerSeconds > 0,
            ),
            _TopBarBtn(
              icon: Icons.grid_on,
              onTap: () => setState(() => _showGrid = !_showGrid),
              active: _showGrid,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildBottomControls() => Positioned(
    bottom: 0, left: 0, right: 0,
    child: Container(
      padding: const EdgeInsets.only(bottom: 40, top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _openGallery,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(Icons.photo_library_outlined, color: Colors.white70),
              ),
            ),
            _buildShutter(),
            GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 52, height: 52,
                decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildShutter() => ScaleTransition(
    scale: _shutterScaleAnim,
    child: GestureDetector(
      onTap: _onShutterPressed,
      child: Container(
        width: 76, height: 76,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  DISPLAY PICTURE SCREEN
// ─────────────────────────────────────────────
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final int?   adventureId;
  final int?   userId;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    this.adventureId,
    this.userId,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

// ── Enum pour l'état GPS ──────────────────────
enum _GpsState { loading, ready, failed }

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late String _currentPath;
  int    _selectedFilter = 0;
  bool   _isUploading    = false;
  double _uploadProgress = 0.0;
  String _uploadStatus   = '';

  // GPS — on distingue 3 états clairement
  _GpsState _gpsState = _GpsState.loading;
  double?   _latitude;
  double?   _longitude;

  final TextEditingController _captionController = TextEditingController();

  static const List<Map<String, Object?>> _filters = [
    {'label': 'Original', 'matrix': null},
    {'label': 'N&B',   'matrix': <double>[0.33,0.33,0.33,0.0,0.0, 0.33,0.33,0.33,0.0,0.0, 0.33,0.33,0.33,0.0,0.0, 0.0,0.0,0.0,1.0,0.0]},
    {'label': 'Sépia', 'matrix': <double>[0.393,0.769,0.189,0.0,0.0, 0.349,0.686,0.168,0.0,0.0, 0.272,0.534,0.131,0.0,0.0, 0.0,0.0,0.0,1.0,0.0]},
    {'label': 'Fade',  'matrix': <double>[1.0,0.0,0.0,0.0,40.0, 0.0,1.0,0.0,0.0,40.0, 0.0,0.0,1.0,0.0,40.0, 0.0,0.0,0.0,1.0,0.0]},
    {'label': 'Vivid', 'matrix': <double>[1.4,-0.1,-0.1,0.0,0.0, -0.1,1.4,-0.1,0.0,0.0, -0.1,-0.1,1.4,0.0,0.0, 0.0,0.0,0.0,1.0,0.0]},
    {'label': 'Cool',  'matrix': <double>[0.8,0.0,0.0,0.0,0.0, 0.0,0.9,0.0,0.0,0.0, 0.0,0.0,1.2,0.0,0.0, 0.0,0.0,0.0,1.0,0.0]},
    {'label': 'Warm',  'matrix': <double>[1.2,0.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0,0.0, 0.0,0.0,0.8,0.0,0.0, 0.0,0.0,0.0,1.0,0.0]},
  ];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
    debugPrint('📸 [display] initState — adventureId=${widget.adventureId} userId=${widget.userId}');
    _fetchLocation();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    debugPrint('📍 [GPS] _fetchLocation — start');
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      debugPrint('📍 [GPS] permission = $perm');

      if (perm == LocationPermission.deniedForever) {
        debugPrint('🔴 [GPS] permission refusée définitivement → gpsState=failed');
        if (mounted) setState(() => _gpsState = _GpsState.failed);
        return;
      }
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        debugPrint('📍 [GPS] permission après demande = $perm');
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          debugPrint('🔴 [GPS] permission refusée → gpsState=failed');
          if (mounted) setState(() => _gpsState = _GpsState.failed);
          return;
        }
      }

      debugPrint('📍 [GPS] récupération position en cours…');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint('📍 [GPS] ✅ position obtenue lat=${pos.latitude} lng=${pos.longitude} accuracy=${pos.accuracy}m');

      if (mounted) {
        setState(() {
          _latitude  = pos.latitude;
          _longitude = pos.longitude;
          _gpsState  = _GpsState.ready;
        });
        debugPrint('📍 [GPS] setState → gpsState=ready lat=$_latitude lng=$_longitude');
      }
    } catch (e) {
      debugPrint('🔴 [GPS] erreur _fetchLocation : $e');
      // Timeout ou autre erreur → on laisse publier sans coordonnées
      if (mounted) setState(() => _gpsState = _GpsState.failed);
    }
  }

  // ── Publish ──────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    // Sécurité : ne devrait pas arriver car le bouton est désactivé en loading,
    // mais on garde le guard au cas où.
    if (_gpsState == _GpsState.loading) {
      debugPrint('⚠️  [publish] GPS encore en cours — appui ignoré');
      return;
    }

    debugPrint('🟩 [publish] start — gpsState=$_gpsState lat=$_latitude lng=$_longitude');
    debugPrint('🟩 [publish] userId=${widget.userId} adventureId=${widget.adventureId}');

    if (widget.userId == null) {
      debugPrint('🔴 [publish] userId null → abort');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non identifié'), backgroundColor: kError),
      );
      return;
    }
    if (widget.adventureId == null) {
      debugPrint('🔴 [publish] adventureId null → abort');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune aventure en cours'), backgroundColor: kError),
      );
      return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0.0; _uploadStatus = 'Préparation…'; });

    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentSession == null) throw Exception('Session expirée');

      // Upload image
      final bytes    = await File(_currentPath).readAsBytes();
      final fileName = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('🟩 [publish] upload $fileName (${bytes.length} bytes)');
      setState(() { _uploadProgress = 0.2; _uploadStatus = 'Upload en cours…'; });

      await supabase.storage
          .from(dotenv.env['SUPABASE_BUCKET']!)
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));

      setState(() { _uploadProgress = 0.6; _uploadStatus = 'Génération du lien…'; });
      final publicUrl = supabase.storage
          .from(dotenv.env['SUPABASE_BUCKET']!)
          .getPublicUrl(fileName);
      debugPrint('🟩 [publish] publicUrl = $publicUrl');

      // Vérification POI
      setState(() { _uploadProgress = 0.75; _uploadStatus = 'Vérification des POI…'; });
      List<dynamic> unlockedBadges = [];
      int? nearestPoiId;

      if (_latitude != null && _longitude != null) {
        debugPrint('📍 [publish] recherche POI proches lat=$_latitude lng=$_longitude');
        try {
          final nearbyPois = await fetchNearbyPoi(_latitude!, _longitude!);
          debugPrint('📍 [publish] ${nearbyPois.length} POI trouvé(s)');

          if (nearbyPois.isNotEmpty) {
            nearestPoiId = nearbyPois[0]['id'] as int?;
            debugPrint('📍 [publish] POI le plus proche id=$nearestPoiId name=${nearbyPois[0]['name']}');
          }

          for (final poi in nearbyPois) {
            debugPrint('📍 [publish] tentative unlock badge poiId=${poi['id']}');
            final result = await unlockBadge(widget.userId!, poi['id'] as int);
            debugPrint('📍 [publish] unlockBadge result=$result');
            if (result['already_unlocked'] == false) {
              unlockedBadges.add(poi);
              debugPrint('🏆 [publish] nouveau badge débloqué : ${poi['name']}');
            }
          }
        } catch (e) {
          debugPrint('🔴 [publish] erreur vérification POI : $e');
        }
      } else {
        debugPrint('⚠️  [publish] pas de coordonnées → POI ignorés');
      }

      setState(() { _uploadProgress = 0.88; _uploadStatus = 'Enregistrement en base…'; });
      debugPrint('🟩 [publish] postPhoto lat=$_latitude lng=$_longitude poiId=$nearestPoiId');

      await postPhoto(
        userId:      widget.userId!,
        adventureId: widget.adventureId!,
        imageUrl:    publicUrl,
        description: _captionController.text.trim().isEmpty
            ? null : _captionController.text.trim(),
        latitude:    _latitude,
        longitude:   _longitude,
        poiId:       nearestPoiId,
      );
      debugPrint('🟩 [publish] postPhoto OK ✅');

      setState(() { _uploadProgress = 1.0; _uploadStatus = 'Publié !'; });
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      if (unlockedBadges.isNotEmpty) {
        _showBadgeUnlockedDialog(unlockedBadges);
      }

    } catch (e) {
      debugPrint('🔴 [publish] erreur : $e');
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: kError),
      );
    }
  }

  void _showBadgeUnlockedDialog(List<dynamic> badges) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(0.12),
                  border: Border.all(color: kPrimary, width: 2),
                ),
                child: const Icon(Icons.emoji_events, color: kPrimary, size: 32),
              ),
              const SizedBox(height: 12),
              const Text('Badge débloqué !',
                style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Tu as découvert un nouveau lieu',
                style: TextStyle(color: kTextMid, fontSize: 13)),
              const SizedBox(height: 16),
              ...badges.map((poi) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: kPrimary.withOpacity(0.12)),
                      child: const Icon(Icons.star, color: kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(poi['badge_name'] ?? poi['name'],
                          style: const TextStyle(
                            color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                        if (poi['badge_description'] != null) ...[
                          const SizedBox(height: 2),
                          Text(poi['badge_description'],
                            style: const TextStyle(color: kTextMid, fontSize: 12)),
                        ],
                      ],
                    )),
                  ]),
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Super !',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgCard2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final sel    = _selectedFilter == i;
                  final matrix = _filters[i]['matrix'];
                  return GestureDetector(
                    onTap: () { setS(() {}); setState(() => _selectedFilter = i); },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? kPrimary : Colors.transparent, width: 2)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: matrix == null
                                ? Image.file(File(_currentPath), fit: BoxFit.cover)
                                : ColorFiltered(
                                    colorFilter: ColorFilter.matrix(matrix as List<double>),
                                    child: Image.file(File(_currentPath), fit: BoxFit.cover),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_filters[i]['label'] as String,
                          style: TextStyle(
                            color: sel ? kPrimary : kTextMid, fontSize: 11,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ]),
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

  Future<void> _saveToGallery() async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        if (!await Gal.requestAccess(toAlbum: true)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission galerie refusée'), backgroundColor: kError),
          );
          return;
        }
      }
      await Gal.putImage(_currentPath, album: 'SekaiAtlas');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo sauvegardée ✓'), backgroundColor: kSuccess),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: kError),
      );
    }
  }

  Future<void> _shareImage() async {
    try {
      await Share.shareXFiles(
        [XFile(_currentPath)],
        text: _captionController.text.trim().isEmpty
            ? null : _captionController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: kError),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final matrix = _filters[_selectedFilter]['matrix'];
    final img = matrix == null
        ? Image.file(File(_currentPath), fit: BoxFit.cover,
            width: double.infinity, height: double.infinity)
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix as List<double>),
            child: Image.file(File(_currentPath), fit: BoxFit.cover,
                width: double.infinity, height: double.infinity),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          img,
          if (_isUploading) _buildUploadOverlay(),
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    _CircleBtn(icon: Icons.arrow_back,
                      onTap: _isUploading ? () {} : () => Navigator.pop(context)),
                    const Spacer(),
                    _CircleBtn(icon: Icons.download,
                      onTap: _isUploading ? () {} : _saveToGallery),
                    const SizedBox(width: 10),
                    _CircleBtn(icon: Icons.share,
                      onTap: _isUploading ? () {} : _shareImage),
                  ]),
                ),
              ),
            ),
          ),
          // Bottom bar
          if (!_isUploading)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                    20, 24, 20, MediaQuery.of(context).padding.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomActionBtn(
                          icon: Icons.color_lens_outlined,
                          label: 'Filtre',
                          onTap: _showFilterSheet,
                          active: _selectedFilter != 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ajouter une description…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white12,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    // ── Bouton Publier avec état GPS ─────────────────
                    _buildPublishButton(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bouton "Publier" qui reflète l'état GPS :
  /// - loading  → spinner + "Localisation en cours…" + désactivé
  /// - ready    → bouton normal vert/actif
  /// - failed   → bouton actif mais avec icône warning + "Publier sans localisation"
  Widget _buildPublishButton() {
    switch (_gpsState) {
      case _GpsState.loading:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null, // désactivé
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary.withOpacity(0.45),
              disabledBackgroundColor: kPrimary.withOpacity(0.45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.8),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Localisation en cours…',
                  style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        );

      case _GpsState.failed:
        return Column(
          children: [
            // Petit avertissement au-dessus du bouton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_off, color: Colors.orange, size: 13),
                  SizedBox(width: 6),
                  Text(
                    'GPS indisponible — photo publiée sans coordonnées',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shadowColor: kPrimary.withOpacity(0.4),
                ),
                child: const Text('Publier',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );

      case _GpsState.ready:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
              shadowColor: kPrimary.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.location_on, size: 16, color: Colors.white70),
                SizedBox(width: 6),
                Text('Publier',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildUploadOverlay() => Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(
              value: _uploadProgress, strokeWidth: 3,
              color: kPrimary, backgroundColor: kPrimary.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 16),
          Text('${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_uploadStatus,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(size.width/3, 0), Offset(size.width/3, size.height), p);
    canvas.drawLine(Offset(size.width*2/3, 0), Offset(size.width*2/3, size.height), p);
    canvas.drawLine(Offset(0, size.height/3), Offset(size.width, size.height/3), p);
    canvas.drawLine(Offset(0, size.height*2/3), Offset(size.width, size.height*2/3), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool active;
  const _TopBarBtn({required this.icon, required this.onTap, this.label, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? kPrimary.withOpacity(0.25) : Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? kPrimary : Colors.white, size: 20),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(label!, style: TextStyle(color: active ? kPrimary : Colors.white, fontSize: 12)),
        ],
      ]),
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _BottomActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _BottomActionBtn({
    required this.icon, required this.label,
    required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Icon(icon, color: active ? kPrimary : Colors.white, size: 24),
      const SizedBox(height: 4),
      Text(label,
        style: TextStyle(color: active ? kPrimary : Colors.white70, fontSize: 11)),
    ]),
  );
}