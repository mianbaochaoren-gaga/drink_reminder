import 'package:flutter/material.dart';

// 这是纯界面预览版，仅用于在浏览器中查看 App 长什么样
// 真正的 iOS 版代码在 main.dart 里，包含完整的通知和提醒功能

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '喝水提醒',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DrinkReminderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DrinkReminderPage extends StatefulWidget {
  const DrinkReminderPage({super.key});

  @override
  State<DrinkReminderPage> createState() => _DrinkReminderPageState();
}

class _DrinkReminderPageState extends State<DrinkReminderPage> {
  int drinkCount = 0;
  int intervalMinutes = 60;
  bool isReminderOn = false;
  static const int dailyGoal = 8;

  void _toggleReminder() {
    setState(() => isReminderOn = !isReminderOn);
  }

  void _addCup() {
    setState(() => drinkCount++);
  }

  void _changeInterval(int? value) {
    if (value == null) return;
    setState(() => intervalMinutes = value);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (drinkCount / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('喝水提醒')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.blue.shade100,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.blue.shade400),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$drinkCount / $dailyGoal',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('杯', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addCup,
              icon: const Icon(Icons.water_drop, size: 28),
              label: const Text('记录一杯', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('提醒间隔',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: intervalMinutes,
                      isExpanded: true,
                      items: [30, 45, 60, 90, 120]
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text('每 $v 分钟'),
                              ))
                          .toList(),
                      onChanged: _changeInterval,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleReminder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isReminderOn ? Colors.red : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isReminderOn ? '关闭提醒' : '开启提醒',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
