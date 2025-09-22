import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/drawing_model.dart';

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
  Future<List<Drawing>> getUserDrawings() async {
    final user = _auth.currentUser;
    // Если пользователя нет, возвращаем пустой список.
    if (user == null) return [];

    // Делаем запрос в Firestore, сортируем по дате.
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('drawings')
        .orderBy('createdAt', descending: true)
        .get();

    // Преобразуем список документов в список объектов Drawing.
    // Теперь мы получаем не только картинку, но и ее уникальный ID.
    return snapshot.docs.map((doc) {
      return Drawing(
        id: doc.id, // Получаем ID документа
        base64Image: doc['imageData'] as String, // Получаем данные изображения
      );
    }).toList();
  }

  Future<void> updateDrawing(String id, String newBase64Image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('drawings')
        .doc(id)
        .update({'imageData': newBase64Image});
  }
}