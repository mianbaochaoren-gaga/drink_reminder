import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 只在非 Web 环境下初始化时区和通知（Web 仅用于预览界面）
  if (!kIsWeb) {
    tz_data.initializeTimeZones();

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(iOS: iosInit);
    await notificationsPlugin.initialize(initSettings);
  }

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 加载本地存储数据
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('date') ?? '';

    setState(() {
      drinkCount = (savedDate == today) ? (prefs.getInt('count') ?? 0) : 0;
      intervalMinutes = prefs.getInt('interval') ?? 60;
      isReminderOn = prefs.getBool('isOn') ?? false;
    });
  }

  // 保存数据
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('date', today);
    await prefs.setInt('count', drinkCount);
    await prefs.setInt('interval', intervalMinutes);
    await prefs.setBool('isOn', isReminderOn);
  }

  // 请求通知权限
  Future<void> _requestPermission() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // 设置定时提醒
  Future<void> _scheduleReminder(int minutes) async {
    await notificationsPlugin.cancelAll();

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: minutes));

    await notificationsPlugin.zonedSchedule(
      0,
      '💧 喝水提醒',
      '该喝水啦！保持健康，从一杯水开始。',
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 关闭提醒
  Future<void> _cancelReminder() async {
    await notificationsPlugin.cancelAll();
  }

  void _toggleReminder() async {
    await _requestPermission();
    if (isReminderOn) {
      await _cancelReminder();
      setState(() => isReminderOn = false);
    } else {
      await _scheduleReminder(intervalMinutes);
      setState(() => isReminderOn = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已开启提醒，每 $intervalMinutes 分钟提醒一次')),
        );
      }
    }
    _saveData();
  }

  void _addCup() {
    setState(() => drinkCount++);
    _saveData();
  }

  void _changeInterval(int? value) {
    if (value == null) return;
    setState(() => intervalMinutes = value);
    if (isReminderOn) {
      _scheduleReminder(value);
    }
    _saveData();
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
