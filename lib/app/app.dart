import 'package:flutter/material.dart';

class ESMSApp extends StatelessWidget {
  const ESMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('ESMS'))),
    );
  }
}
