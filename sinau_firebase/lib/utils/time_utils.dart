import 'package:cloud_firestore/cloud_firestore.dart';

class TimeUtils {
  static String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    // Format sederhana, Anda bisa menggunakan package 'intl' untuk format yang lebih kompleks
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
