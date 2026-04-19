import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Servicio base de Firebase para gestionar la conexión y sincronización
/// Maneja autenticación anónima y acceso a Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  String? _deviceId;
  bool _initialized = false;
  // Timer? _authRetryTimer;
  Completer<bool>? _initializationCompleter;

  /// Getter para Firestore
  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase no está inicializado. Llama a initialize() primero.');
    }
    return _firestore!;
  }

  /// Getter para Auth
  FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase no está inicializado. Llama a initialize() primero.');
    }
    return _auth!;
  }

  /// ID del dispositivo actual (basado en el usuario anónimo)
  String get deviceId => _deviceId ?? 'unknown';

  /// Verifica si Firebase está inicializado
  bool get isInitialized => _initialized;

  /// Inicializar Firebase
  /// Debe ser llamado al inicio de la aplicación
  Future<bool> initialize() async {
    if (_initialized) {
      debugPrint('Firebase ya está inicializado');
      return true;
    }

    if (_initializationCompleter != null) {
      return await _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<bool>();

    try {
      // Inicializar Firebase Core si no existe
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: MyFirebaseOptions.currentPlatform,
        );
      }

      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;

      // Configurar persistencia offline (solo si no se ha configurado ya)
      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        // Ignorar error si ya estaba configurado
        debugPrint('Nota: Configuración de Firestore ya establecida o no modificable.');
      }

      // Autenticación anónima para identificar dispositivos
      await _authenticateAnonymously();

      _initialized = true;
      debugPrint('Firebase inicializado correctamente');
      _initializationCompleter!.complete(true);
      return true;
    } catch (e) {
      debugPrint('Error al inicializar Firebase: $e');
      _initializationCompleter!.complete(false);
      // _initializationCompleter = null; // Permitir reintento
      return false;
    }
  }

  /// Autenticación anónima
  Future<void> _authenticateAnonymously() async {
    try {
      UserCredential userCredential;

      if (_auth!.currentUser == null) {
        // Si no hay usuario, crear uno anónimo
        userCredential = await _auth!.signInAnonymously();
        debugPrint('Usuario anónimo creado: ${userCredential.user?.uid}');
      } else {
        debugPrint('Usuario existente: ${_auth!.currentUser?.uid}');
      }

      _deviceId = _auth!.currentUser?.uid ?? 'unknown';
      // _authRetryTimer?.cancel();
    } catch (e) {
      debugPrint('Error en autenticación anónima: $e');
      _deviceId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      // _scheduleAuthRetry();
    }
  }

  // void _scheduleAuthRetry() {
  //   _authRetryTimer?.cancel();
  //   _authRetryTimer = null;

  //   if (_auth?.currentUser != null) {
  //     return; // Evitar timer innecesario
  //   }
  //   _authRetryTimer = Timer(const Duration(seconds: 15), () async {
  //     if (_auth?.currentUser == null) {
  //       debugPrint('Reintentando autenticación anónima...');
  //       await _authenticateAnonymously();
  //     }
  //     _authRetryTimer = null;
  //   });
  // }

  /// Verificar conectividad con Firebase
  Future<bool> checkConnection() async {
    try {
      await _firestore!
          .collection('_health_check')
          .doc('ping')
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('No hay conexión a Firebase: $e');
      return false;
    }
  }

  /// Métodos genéricos para CRUD en Firestore

  /// Crear o actualizar un documento
  Future<bool> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore!
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
      return true;
    } catch (e) {
      debugPrint('Error al guardar documento: $e');
      return false;
    }
  }

  /// Obtener un documento
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore!.collection(collection).doc(docId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error al obtener documento: $e');
      return null;
    }
  }

  /// Eliminar un documento
  Future<bool> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore!.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar documento: $e');
      return false;
    }
  }

  /// Obtener colección completa
  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      debugPrint('📥 Obteniendo colección: $collection');
      final snapshot = await _firestore!.collection(collection).get().timeout(
        timeout,
        onTimeout: () {
          debugPrint('⏱️ Timeout al obtener colección $collection');
          throw TimeoutException('Timeout obteniendo $collection');
        },
      );
      debugPrint('✅ Colección $collection obtenida: ${snapshot.docs.length} documentos');
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error al obtener colección $collection: $e');
      return [];
    }
  }

  /// Escuchar cambios en una colección (sincronización en tiempo real)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection({
    required String collection,
  }) {
    debugPrint('👀 Iniciando watch en colección: $collection');
    return _firestore!.collection(collection).snapshots();
  }

  /// Escuchar cambios en un documento específico
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore!.collection(collection).doc(docId).snapshots();
  }

  /// Batch write para operaciones múltiples
  /// Divide automáticamente en chunks de 100 (límite de Firestore)
  Future<bool> batchWrite({
    required List<Map<String, dynamic>> operations,
  }) async {
    try {
      if (operations.isEmpty) {
        debugPrint('⚠️ No hay operaciones para ejecutar en batch');
        return true;
      }

      const int batchLimit = 100;
      final totalBatches = (operations.length / batchLimit).ceil();

      debugPrint(
          '📦 Iniciando batch write: ${operations.length} operaciones en $totalBatches lote(s)');

      final batch = _firestore!.batch();
      // Dividir operaciones en chunks de 500
      for (int i = 0; i < operations.length; i += batchLimit) {
        final end =
            (i + batchLimit < operations.length) ? i + batchLimit : operations.length;
        final chunk = operations.sublist(i, end);

        if (chunk.isEmpty) continue;

        for (final op in chunk) {
          final docRef = _firestore!.collection(op['collection']).doc(op['docId']);

          if (op['type'] == 'set') {
            batch.set(docRef, op['data'], SetOptions(merge: true));
          } else if (op['type'] == 'delete') {
            batch.delete(docRef);
          } else if (op['type'] == 'update') {
            batch.update(docRef, op['data']);
          }
        }

        await batch.commit();
        final batchNumber = i ~/ batchLimit + 1;
        debugPrint(
            '✅ Lote $batchNumber/$totalBatches completado: ${chunk.length} operaciones');
      }

      debugPrint('✅ Batch write completado: ${operations.length} operaciones ejecutadas');
      return true;
    } catch (e) {
      debugPrint('❌ Error en batch write: $e');
      return false;
    }
  }

  /// Agregar metadata de sincronización a los datos
  Map<String, dynamic> addSyncMetadata(Map<String, dynamic> data) {
    return {
      ...data,
      'syncMetadata': {
        'deviceId': deviceId,
        'lastModified': FieldValue.serverTimestamp(),
        'version': 1,
      },
    };
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    // _authRetryTimer?.cancel();
    // _authRetryTimer = null;
    _initialized = false;
    _firestore = null;
    _auth = null;
    _deviceId = null;
  }
}

class MyFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
          apiKey: 'AIzaSyBo-LfWgBG5WpnoQy9y0b3qunOSWLT5vMY',
          appId: '1:407728281687:web:695b18ae3ad9244783eb12',
          messagingSenderId: '407728281687',
          projectId: 'in-out-15bb6');
    } else {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBo-LfWgBG5WpnoQy9y0b3qunOSWLT5vMY',
        appId: '1:407728281687:android:c501493ceb53a55683eb12',
        messagingSenderId: '407728281687',
        projectId: 'in-out-15bb6',
      );
    }
  }
}
