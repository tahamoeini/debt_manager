import 'package:flutter/material.dart';

class DebtManagerApp extends StatelessWidget {
	const DebtManagerApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Debt Manager',
			debugShowCheckedModeBanner: false,
			themeMode: ThemeMode.dark,
			theme: ThemeData(
				useMaterial3: true,
				colorScheme: ColorScheme.fromSeed(
					seedColor: const Color(0xFF4CAF50),
					brightness: Brightness.dark,
				),
			),
			home: Scaffold(
				appBar: AppBar(
					title: Text('Debt Manager'),
				),
				body: Center(
					child: Text('Debt Manager – placeholder'),
				),
			),
		);
	}
}

