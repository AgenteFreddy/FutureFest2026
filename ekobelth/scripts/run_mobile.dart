import 'dart:io';

void main(List<String> args) async {
  print('Buscando o IP local do PC na rede...');

  String? localIp;
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          if (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            localIp = addr.address;
            break;
          }
        }
      }
      if (localIp != null) break;
    }
  } catch (e) {
    print(
      'Aviso: Não foi possível obter as interfaces de rede automaticamente.',
    );
  }

  localIp ??= '127.0.0.1';

  print('==================================================');
  print('🚀 IP detectado: $localIp');
  print('==================================================\n');
  print('Iniciando flutter run...');

  var process = await Process.start('flutter', [
    'run',
    '--dart-define=API_BASE_URL=http://$localIp:8000',
    '--dart-define=IA_BASE_URL=http://$localIp:8001',
    ...args,
  ], mode: ProcessStartMode.inheritStdio);

  await process.exitCode;
}
