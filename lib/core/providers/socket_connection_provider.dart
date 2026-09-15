import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

final socketConnectionProvider = StreamProvider<bool>((ref) {
  // Start with current connected state
  return SocketService.instance.connectionStateStream;
});

