import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Indica se o plugin foi inicializado com sucesso nesta plataforma.
  bool _inicializado = false;
  Future<void>? _initFuture;

  /// Se o Android permite alarmes exatos (Android 12+ pode negar).
  bool _podeAlarmeExato = true;

  /// Inicializa o plugin uma única vez. Chamadas repetidas reutilizam
  /// a mesma inicialização. Em plataformas sem suporte (ex.: web) não faz nada.
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
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Android 13+: pede permissão para exibir notificações.
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
      // TZDateTime.from preserva o instante absoluto do DateTime local,
      // então o horário agendado é o correto independente de tz.local.
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
      // Sem permissão de alarme exato, usa o modo inexato em vez de falhar.
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
