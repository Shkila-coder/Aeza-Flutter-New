import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Метод для сохранения рисунка в виде строки Base64.
  Future<void> saveDrawing(String base64Image) async {
    // Получаем текущего пользователя.
    final user = _auth.currentUser;
    // Если пользователь не авторизован, прерываем операцию с ошибкой.
    if (user == null) throw Exception("Пользователь не авторизован");

    // Создаём новый документ в подколлекции 'drawings' для текущего пользователя.
    // Структура данных: users/{userId}/drawings/{drawingId}
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('drawings')
        .add({
      'imageData': base64Image, // Сохраняем саму картинку.
      'createdAt': Timestamp.now(), // Добавляем временную метку для сортировки.
    });
  }

  // Метод для получения всех рисунков текущего пользователя.
  Future<List<String>> getUserDrawings() async {
    final user = _auth.currentUser;
    // Если пользователя нет, возвращаем пустой список.
    if (user == null) return [];

    // Делаем запрос в Firestore: получаем все документы из подколлекции 'drawings' пользователя.
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('drawings')
        .orderBy('createdAt', descending: true) // Сортируем по дате, чтобы новые были сверху.
        .get();

    // Преобразуем (map) список документов в список строк (base64Image).
    return snapshot.docs.map((doc) => doc['imageData'] as String).toList();
  }
}