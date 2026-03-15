import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(storageService: StorageService()),
        ),
      ],
      child: MaterialApp(
        title: 'TH4 Core Layers',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          scaffoldBackgroundColor: const Color(0xFFF7F7F5),
          useMaterial3: true,
        ),
        home: const CoreOnlyScreen(),
      ),
    );
  }
}

class CoreOnlyScreen extends StatelessWidget {
  const CoreOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Core layers only: models, services, providers, utils'),
      ),
    );
  }
}
