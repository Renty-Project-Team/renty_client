import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/main.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';


class SignalRTestPage extends StatefulWidget {
  const SignalRTestPage({Key? key}) : super(key: key);

  @override
  _SignalRTestPageState createState() => _SignalRTestPageState();
}

class _SignalRTestPageState extends State<SignalRTestPage> {
  final String _hubUrl = "${apiClient.getDomain}/chathub"; // Android Emulator용 로컬 ASP.NET Core 주소 (HTTP)
  
  HubConnection? _hubConnection;
  final TextEditingController _userController = TextEditingController(text: "FlutterUser");
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _receiverUserIdController = TextEditingController(); // 특정 유저에게 보낼 때 사용

  List<String> _receivedMessages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _createHubConnection();
  }


  Future<void> _createHubConnection() async {
    var options = HttpConnectionOptions(
      accessTokenFactory: () async => await TokenManager.getToken() ?? "", // 토큰을 가져오는 비동기 함수
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: options,
        )
        .build();

    _hubConnection?.onclose(({error}) { // 인자 이름이 error (소문자) 또는 exception 일 수 있음, 확인 필요
          print("SignalR: Connection Closed: $error");
          if (mounted) {
            setState(() { _isConnected = false; _addMessageToLog("SignalR 연결 끊김: ${error ?? "이유 모름"}"); });
          }
      });

    // 서버에서 "ReceiveMessage" 호출 시 실행될 핸들러 등록
    _hubConnection?.on("_handleIncomingMessage", (arguments) {
      if (arguments != null) {
        final json = arguments[0] as Map<String, dynamic>;
        final logMessage = "메시지 수신: $json";
        print("SignalR: $logMessage");
        _addMessageToLog(logMessage);
      }
    });

    // (선택) 다른 서버 이벤트 핸들러 등록
    // _hubConnection?.on("UserConnected", (arguments) { ... });
  }

  Future<void> _connectToHub() async {
    if (_hubConnection == null) {
      await _createHubConnection(); // 만약을 위해 다시 생성 시도
    }

    if (_hubConnection?.state == HubConnectionState.Disconnected) {
      try {
        _addMessageToLog("연결 시도 중...");
        await _hubConnection!.start();
        setState(() {
          _isConnected = true;
        });
        _addMessageToLog("연결 성공!");
        print("SignalR: Connected to Hub!");
      } catch (e) {
        print("SignalR: Connection failed: $e");
        _addMessageToLog("연결 실패: $e");
        setState(() {
          _isConnected = false;
        });
      }
    } else {
      _addMessageToLog("이미 연결되어 있거나 연결 중입니다.");
    }
  }

  Future<void> _disconnectFromHub() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      _addMessageToLog("연결 해제 시도 중...");
      await _hubConnection!.stop();
      // onclose에서 _isConnected = false 처리되므로 여기서 중복 호출 안해도 됨
      // (만약 onclose가 즉시 호출되지 않는다면 여기서 상태 변경 필요)
      _addMessageToLog("연결 해제 완료 (서버 응답).");
    } else {
      _addMessageToLog("연결되어 있지 않습니다.");
    }
  }

  Future<void> _sendMessageToAll() async {
    // if (_hubConnection?.state == HubConnectionState.Connected) {
    //   if (_userController.text.isEmpty || _messageController.text.isEmpty) {
    //     _addMessageToLog("사용자 이름과 메시지를 입력하세요.");
    //     return;
    //   }
    //   try {
    //     // 서버의 "SendMessageToAll" 메소드 호출
    //     await _hubConnection?.invoke("SendMessageToAll", args: [
    //       _userController.text,
    //       _messageController.text,
    //     ]);
    //     _addMessageToLog("전체 메시지 전송: ${_userController.text}: ${_messageController.text}");
    //     _messageController.clear();
    //   } catch (e) {
    //     print("SignalR: Error sending message to all: $e");
    //     _addMessageToLog("전체 메시지 전송 실패: $e");
    //   }
    // } else {
    //   _addMessageToLog("연결되어 있지 않아 메시지를 보낼 수 없습니다.");
    // }
  }

  // 특정 사용자에게 보내는 기능 (서버 Hub에 해당 메소드가 있어야 함)
  Future<void> _sendMessageToUser() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      if (_messageController.text.isEmpty) {
        _addMessageToLog("메시지를 입력하세요.");
        return;
      }
      try {
        await _hubConnection?.invoke("SendMessage", args: [ 
          int.parse(_receiverUserIdController.text), // 방 번호
          _messageController.text, // 메세지 내용
          "Text" // 메세지 타입 (Text, Image 등)
        ]);
        _addMessageToLog("메시지 전송 -> ${_messageController.text}");
        _messageController.clear();
      } catch (e) {
        print("SignalR: Error sending message to user: $e");
        _addMessageToLog("특정 사용자 메시지 전송 실패: $e");
      }
    } else {
      _addMessageToLog("연결되어 있지 않아 메시지를 보낼 수 없습니다.");
    }
  }


  void _addMessageToLog(String message) {
    setState(() {
      // 최신 메시지가 위로 오도록 추가
      _receivedMessages.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)}: $message");
      if (_receivedMessages.length > 100) { // 로그 너무 많아지는 것 방지
        _receivedMessages.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _hubConnection?.stop(); // 페이지 종료 시 연결 해제
    _userController.dispose();
    _messageController.dispose();
    _receiverUserIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SignalR 테스트"),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.link_off : Icons.link),
            tooltip: _isConnected ? "연결 해제" : "연결",
            onPressed: _isConnected ? _disconnectFromHub : _connectToHub,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("연결 상태: ${_isConnected ? '연결됨' : '끊김'}",
                style: TextStyle(color: _isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "사용자 이름 (발신자)"),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: "메시지 내용"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isConnected ? _sendMessageToAll : null,
              child: const Text("모두에게 메시지 보내기"),
            ),
            const SizedBox(height: 20),
            const Text("특정 사용자에게 보내기 (서버 구현 필요):", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _receiverUserIdController,
              decoration: const InputDecoration(labelText: "수신자 User ID"),
            ),
            ElevatedButton(
              onPressed: _isConnected ? _sendMessageToUser : null,
              child: const Text("특정 사용자에게 메시지 보내기"),
            ),
            const SizedBox(height: 20),
            const Text("로그:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListView.builder(
                  reverse: true, // 최신 로그가 아래에 오도록 하려면 false, 위에 오도록 하려면 true
                  itemCount: _receivedMessages.length,
                  itemBuilder: (context, index) {
                    return Text(_receivedMessages[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}