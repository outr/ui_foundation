import 'package:flutter/material.dart';

import 'foundation.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Application.instance.createMain()
      ),
      bottomNavigationBar: Application.instance.bottomNavBar()
  );
}