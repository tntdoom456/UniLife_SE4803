import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kampus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari Lokasi',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color.fromARGB(255, 47, 46, 46),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 28, 28, 28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey)
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey,),
                  SizedBox(height: 16,),
                  Text(
                    'Ini maps',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),
          )),
          const SizedBox(height: 24,)
        ],
      ),
    );
  }
}
