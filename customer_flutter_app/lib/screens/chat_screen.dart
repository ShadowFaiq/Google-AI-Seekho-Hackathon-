import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String userId;
  final String userName;
  final bool isProvider;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.userId,
    required this.userName,
    this.isProvider = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late WebSocketChannel _channel;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadHistoryAndConnect();
  }

  Future<void> _loadHistoryAndConnect() async {
    try {
      // 1. Fetch History
      final history = await ApiService.getChatHistory(widget.bookingId);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('ChatScreen: History fetch error: $e');
      setState(() {
        _isLoading = false;
      });
    }

    // 2. Connect WebSocket
    try {
      final baseWs = ApiService.baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
      final wsUrl = '$baseWs/ws/chat/${widget.bookingId}/${widget.userId}';
      debugPrint('ChatScreen: Connecting to WS: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      setState(() {
        _isConnected = true;
      });

      _channel.stream.listen(
        (message) {
          debugPrint('ChatScreen: Received: $message');
          final decoded = jsonDecode(message);
          if (decoded is Map<String, dynamic>) {
            setState(() {
              // Deduplicate or append
              final exists = _messages.any((m) => m['message_id'] == decoded['message_id']);
              if (!exists) {
                _messages.add(decoded);
              }
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          debugPrint('ChatScreen: WS Error: $error');
          setState(() {
            _isConnected = false;
          });
        },
        onDone: () {
          debugPrint('ChatScreen: WS Closed');
          setState(() {
            _isConnected = false;
          });
        },
      );
    } catch (e) {
      debugPrint('ChatScreen: WS Connection failed: $e');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_isConnected) {
      final payload = {
        'text': text,
        'sender_id': widget.userId,
      };
      _channel.sink.add(jsonEncode(payload));
      _messageController.clear();
    } else {
      // Offline / Mock fallback
      final mockMsg = {
        'message_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
        'booking_id': widget.bookingId,
        'sender_id': widget.userId,
        'text': text,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      setState(() {
        _messages.add(mockMsg);
      });
      _messageController.clear();
      _scrollToBottom();

      // Trigger automatic provider reply in mock mode
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          final replyMsg = {
            'message_id': 'mock_reply_${DateTime.now().millisecondsSinceEpoch}',
            'booking_id': widget.bookingId,
            'sender_id': widget.isProvider ? 'customer_user' : 'provider_user',
            'text': widget.isProvider ? 'Ok deal, I will be there shortly.' : 'Main raste me hu, 10 min me punchta hu.',
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          };
          setState(() {
            _messages.add(replyMsg);
          });
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_isConnected) {
      _channel.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isProvider ? 'Chat with Customer' : 'Chat with Provider',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF10B981) : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Connected' : 'Mock Mode / Reconnecting',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isConnected ? const Color(0xFF10B981) : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'ID: ${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8) : widget.bookingId}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.mutedTeal))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.mutedText.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No messages yet. Say hello!',
                              style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final senderId = msg['sender_id'] as String;
                          final isSystem = senderId == 'system';
                          final isMe = senderId == widget.userId;

                          if (isSystem) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.divider.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.deepNavy : AppColors.cardWhite,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                ),
                                border: isMe ? null : Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : AppColors.mainText,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTime(msg['timestamp']),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : AppColors.mutedText,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.softIvory,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.mutedTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    } catch (_) {
      return '';
    }
  }
}
