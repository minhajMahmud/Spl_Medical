export 'src/protocol/protocol.dart';
export 'package:serverpod_client/serverpod_client.dart';
import 'package:backend_client/backend_client.dart';

late Client client;

void initServerpodClient({String? url}) {
  // Allow overriding via parameter or environment variable
  // Priority: Parameter > Environment > Localhost
  String serverUrl = url ??
      const String.fromEnvironment('BACKEND_URL',
          defaultValue: 'http://localhost:8080/');
  client = Client(serverUrl);

  print('Serverpod client initialized → $serverUrl');
}
