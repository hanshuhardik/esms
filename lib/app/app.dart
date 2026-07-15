import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class ESMSApp extends StatelessWidget {
  const ESMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ESMS',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
