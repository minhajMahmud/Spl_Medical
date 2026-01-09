export 'src/protocol/protocol.dart';
export 'package:serverpod_client/serverpod_client.dart';
import 'package:backend_client/backend_client.dart';

late Client client;

void initServerpodClient() {
  late String serverUrl = 'http://localhost:8080/';

  client = Client(serverUrl);

  print('Serverpod client initialized → $serverUrl');
}
