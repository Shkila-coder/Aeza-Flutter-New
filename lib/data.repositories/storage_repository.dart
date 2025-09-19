import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Метод для загрузки изображения в виде байтов (Uint8List).
  Future<String> uploadImage(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("Пользователь не авторизован");
      }

      // Генерируем уникальное имя для файла с помощью пакета 'uuid'.
      final String imageId = const Uuid().v4();
      // Создаем ссылку на место в Storage, куда будет загружен файл.
      final ref = _storage.ref('images/${user.uid}/$imageId.png');

      // Загружаем данные.
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask.whenComplete(() => {});

      // Получаем и возвращаем URL для скачивания загруженного файла.
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // Обрабатываем возможные ошибки Firebase при загрузке.
      print('Ошибка при загрузке изображения: $e');
      rethrow;
    }
  }

  // Метод для получения URL всех изображений пользователя.
  Future<List<String>> getUserImages() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Получаем список всех элементов в папке пользователя.
      final ListResult result = await _storage.ref('images/${user.uid}').listAll();
      // Для каждого элемента асинхронно запрашиваем его URL.
      final List<Future<String>> urlFutures = result.items.map((ref) => ref.getDownloadURL()).toList();

      // Дожидаемся выполнения всех запросов и возвращаем список готовых URL.
      final List<String> urls = await Future.wait(urlFutures);
      return urls;
    } on FirebaseException catch (e) {
      // Если Firebase говорит, что папка не найдена (например, у нового пользователя),
      // это не ошибка. Просто возвращаем пустой список.
      if (e.code == 'object-not-found') {
        return [];
      }
      // Все другие ошибки считаем критическими.
      rethrow;
    }
  }
}