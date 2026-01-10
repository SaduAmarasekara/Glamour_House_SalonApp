import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid, name, email, role;
  final String? phone;

  UserModel({required this.uid, required this.name, required this.email, required this.role, this.phone});

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'email': email, 'role': role, 'phone': phone
  };
}

class Appointment {
  final String? id;
  final String customerId;
  final String customerName;
  final String? customerEmail; // අලුතින් එකතු කළා
  final String? customerPhone; // අලුතින් එකතු කළා
  final String service;
  final String status;
  final String? notes; // අලුතින් එකතු කළා
  final DateTime dateTime;
  final DateTime? createdAt; // අලුතින් එකතු කළා

  Appointment({
    this.id,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.service,
    required this.status,
    this.notes,
    required this.dateTime,
    this.createdAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Appointment(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'],
      customerPhone: data['customerPhone'],
      service: data['service'] ?? '',
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'service': service,
      'status': status,
      'notes': notes,
      'dateTime': dateTime,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class GalleryPhoto {
  final String? id;
  final String imageUrl;
  final String title;
  final String category;
  final DateTime uploadedAt;
  final String uploadedBy;

  GalleryPhoto({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'category': category,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
    };
  }

  factory GalleryPhoto.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return GalleryPhoto(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }
}