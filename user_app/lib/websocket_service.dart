import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static const String baseUrl = 'ws://localhost:8080/ws';
  
  WebSocketChannel? _channel; // WebSocket channel for user-specific connections
  StreamController<Map<String, dynamic>>? _messageController; // Stream controller for incoming messages
  Timer? _pingTimer; // Timer for periodic ping messages
  String? _currentUserId; // Currently connected user ID
  bool _isConnected = false;// Connection status
  
  // Singleton instance
  // This ensures only one instance of WebSocketService exists
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  bool get isConnected => _isConnected;

// Factory constructor to return the singleton instance
  Future<bool> connectUser(String userId) async {
    try {
      print('Connecting to user WebSocket: $userId');
      _currentUserId = userId;
      
      final uri = Uri.parse('$baseUrl/user/$userId');
      _channel = WebSocketChannel.connect(uri); // Create a WebSocket connection for the user
      
      // Initialize the message controller to handle incoming messages
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      // Listen for incoming messages on the WebSocket channel
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            print('Received WebSocket message: ${data['type']}');
            _messageController?.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      // Set the connection status to true
      _isConnected = true;
      // Start the ping timer to keep the connection alive
      _startPingTimer();
      
      print('Connected to user WebSocket successfully');
      return true;
      
    } catch (e) {
      print('Error connecting to user WebSocket: $e');
      return false;
    }
  }

// This method sends a message to the WebSocket server
  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    
    // Prepare the message with type, data, and user ID
    final message = {
      'type': type,
      'data': data,
      'user_id': _currentUserId,
    };
    
    // Send the message as a JSON-encoded string
    try {
      _channel!.sink.add(jsonEncode(message));
      print('Sent WebSocket message: $type');
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }

// This method starts a periodic timer to send ping messages every minute
  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isConnected && _channel != null) {
        try {
          final pingMessage = {'type': 'ping', 'data': 'ping'};
          // Send a ping message to keep the connection alive
  
          _channel!.sink.add(jsonEncode(pingMessage));
        } catch (e) {
          print('Error sending ping: $e');
          timer.cancel();
        }
      }
    });
  }

// This method disconnects the WebSocket connection and cleans up resources
  void disconnect() {
    print('Disconnecting WebSocket...');
    
    _pingTimer?.cancel();
    _pingTimer = null;
    
    _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _messageController?.close();
    _messageController = null;
    
    _isConnected = false;
    _currentUserId = null;
    
    print('WebSocket disconnected');
  }
}