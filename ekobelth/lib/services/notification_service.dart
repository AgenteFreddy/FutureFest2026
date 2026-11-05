import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  Future<void>? _initFuture;

  bool _podeAlarmeExato = true;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    if (kIsWeb) return;
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(
          defaultActionName: 'Abrir notificação',
        ),
      );
      tz.initializeTimeZones();
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notificação aberta: ${response.payload}');
        },
      );
      _inicializado = true;

      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.requestNotificationsPermission();
        _podeAlarmeExato =
            await android.canScheduleExactNotifications() ?? false;
      }
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    if (!_inicializado) return;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Medicamentos',
          channelDescription: 'Lembretes de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: _podeAlarmeExato
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_inicializado) return;
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Medicamentos',
          channelDescription: 'Lembretes de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await init();
    if (!_inicializado) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
