import 'package:cloud_firestore/cloud_firestore.dart';

//? Model untuk Jurnal
class JournalModel {
  final String? id;
  final String title;
  final String content;
  final String userId;
  final String username;
  String status;
  final Timestamp createdAt;
  Timestamp? updatedAt;
  Timestamp? publishedAt;
  String? reviewedBy;

//! final berarti variabel tersebut hanya bisa diinisialisasi (diberi nilai) satu kali.

  JournalModel({
    this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.username,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.reviewedBy,
  });

  factory JournalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return JournalModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      status: data['status'] ?? 'created',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      publishedAt: data['publishedAt'],
      reviewedBy: data['reviewedBy'],
    );
  }

  // Untuk mengubah objek JournalModel menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'userId': userId,
      'username': username,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt, // Akan diupdate saat ada perubahan
      'publishedAt': publishedAt,
      'reviewedBy': reviewedBy,
    };
  }
}