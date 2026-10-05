import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';

class SocketService {
  io.Socket? _socket;
  Future<io.Socket> connect() async {
    final token = await ApiClient().storage.read(key: 'accessToken');
    _socket = io.io(
      ApiClient.baseUrl.replaceFirst('/api/v1', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
    _socket!.connect();
    return _socket!;
  }

  io.Socket? get socket => _socket;
  void dispose() {
    _socket?.disconnect();
    _socket = null;
  }
}
