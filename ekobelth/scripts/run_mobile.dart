import 'dart:io';

void main(List<String> args) async {
  print('Buscando o IP local do PC na rede...');
  
  String? localIp;
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          // Procura por IPs típicos de rede local (Wi-Fi / Ethernet)
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
    print('Aviso: Não foi possível obter as interfaces de rede automaticamente.');
  }

  localIp ??= '127.0.0.1'; // Fallback
  
  print('==================================================');
  print('🚀 IP detectado: $localIp');
  print('==================================================\n');
  print('Iniciando flutter run...');

  // Executa o flutter run passando o IP como variável de ambiente (dart-define)
  var process = await Process.start(
    'flutter',
    [
      'run',
      '--dart-define=API_BASE_URL=http://$localIp:8000',
      '--dart-define=IA_BASE_URL=http://$localIp:8001',
      ...args // Permite passar outros argumentos como -d <device>
    ],
    mode: ProcessStartMode.inheritStdio,
  );

  await process.exitCode;
}
