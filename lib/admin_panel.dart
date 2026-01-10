import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'admin_add_photo.dart'; // ඔයා කලින් දුන්න Photo Page එක

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto())),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Appointment apt = Appointment.fromFirestore(snapshot.data!.docs[index]);
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${apt.service} - ${apt.customerName}"),
                  subtitle: Text("Status: ${apt.status}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => FirebaseFirestore.instance.collection('appointments').doc(apt.id).update({'status': 'confirmed'}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('appointments').doc(apt.id).delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}