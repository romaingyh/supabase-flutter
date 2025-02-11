import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockWidget extends StatefulWidget {
  const MockWidget({Key? key}) : super(key: key);

  @override
  State<MockWidget> createState() => _MockWidgetState();
}

class _MockWidgetState extends State<MockWidget> {
  bool isSignedIn = true;

  @override
  Widget build(BuildContext context) {
    return isSignedIn
        ? TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
            },
            child: const Text('Sign out'),
          )
        : const Text('You have signed out');
  }

  @override
  void initState() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          isSignedIn = false;
        });
      }
    });
    super.initState();
  }
}

class MockExpiredStorage extends LocalStorage {
  MockExpiredStorage()
      : super(
          initialize: () async {},

          // Session expires at is at its maximum value for unix timestamp
          accessToken: () async =>
              '{"currentSession":{"token_type": "","access_token":"","expires_in":20,"refresh_token":"","user":{"app_metadata": {},"id":"","aud":"","created_at":"","role":"authenticated","updated_at":""}},"expiresAt":${((DateTime.now().subtract(Duration(seconds: 11))).millisecondsSinceEpoch / 1000).round()}}',
          persistSession: (_) async {},
          removePersistedSession: () async {},
          hasAccessToken: () async => true,
        );
}

class MockLocalStorage extends LocalStorage {
  MockLocalStorage()
      : super(
          initialize: () async {},

          // Session expires at is at its maximum value for unix timestamp
          accessToken: () async =>
              '{"currentSession":{"token_type": "","access_token":"","expires_in":3600,"refresh_token":"","user":{"app_metadata": {},"id":"","aud":"","created_at":"","role":"authenticated","updated_at":""}},"expiresAt":2147483647}',
          persistSession: (_) async {},
          removePersistedSession: () async {},
          hasAccessToken: () async => true,
        );
}

class MockEmptyLocalStorage extends LocalStorage {
  MockEmptyLocalStorage()
      : super(
          initialize: () async {},
          accessToken: () async => null,
          persistSession: (_) async {},
          removePersistedSession: () async {},
          hasAccessToken: () async => false,
        );
}

/// Registers the mock handler for uni_links
void mockAppLink({String? initialLink}) {
  const channel = MethodChannel('com.llfbandit.app_links/messages');
  const anotherChannel = MethodChannel('com.llfbandit.app_links/events');

  TestWidgetsFlutterBinding.ensureInitialized();

  // ignore: invalid_null_aware_operator
  TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => initialLink);

  // ignore: invalid_null_aware_operator
  TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
      .setMockMethodCallHandler(anotherChannel, (message) async => null);
}

class MockAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> getItem({required String key}) async {
    return _map[key];
  }

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }
}

/// Custom HTTP client just to test the PKCE flow.
class PkceHttpClient extends BaseClient {
  int requestCount = 0;
  Map<String, dynamic> lastRequestBody = {};

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    requestCount++;

    if (request is Request) {
      lastRequestBody = jsonDecode(request.body);
    }

    final jwt = JWT(
      {'exp': (DateTime.now().millisecondsSinceEpoch / 1000).round() + 60},
      subject: '18bc7a4e-c095-4573-93dc-e0be29bada97',
    );

    return StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode(
            {
              'access_token': jwt.sign(
                SecretKey('37c304f8-51aa-419a-a1af-06154e63707a'),
              ),
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'tDoDnvj5MKLuZOQ65KyVfQ',
              'user': {
                'id': '18bc7a4e-c095-4573-93dc-e0be29bada97',
                'aud': '',
                'role': '',
                'email': 'fake1@email.com',
                'email_confirmed_at': '2023-04-01T09:38:59.784028Z',
                'phone': '166600000000',
                'phone_confirmed_at': '2023-04-01T09:38:59.784028Z',
                'confirmed_at': '2023-04-01T09:38:59.784028Z',
                'last_sign_in_at': '2023-04-01T09:38:59.904492805Z',
                'app_metadata': {
                  'provider': 'email',
                  'providers': ['email']
                },
                'user_metadata': {},
                'factors': [
                  {
                    'id': '1d3aa138-da96-4aea-8217-af07daa6b82d',
                    'created_at': '2023-04-01T09:38:59.784028Z',
                    'updated_at': '2023-04-01T09:38:59.784028Z',
                    'status': 'unverified',
                    'friendly_name': 'UnverifiedFactor',
                    'factor_type': 'totp'
                  }
                ],
                'identities': [
                  {
                    'id': '18bc7a4e-c095-4573-93dc-e0be29bada97',
                    'user_id': '18bc7a4e-c095-4573-93dc-e0be29bada97',
                    'identity_data': {
                      'email': 'fake1@email.com',
                      'sub': '18bc7a4e-c095-4573-93dc-e0be29bada97'
                    },
                    'provider': 'email',
                    'last_sign_in_at': '2023-04-01T09:38:59.784028Z',
                    'created_at': '2023-04-01T09:38:59.784028Z',
                    'updated_at': '2023-04-01T09:38:59.784028Z'
                  }
                ],
                'created_at': '2023-04-01T09:38:59.784028Z',
                'updated_at': '2023-04-01T09:38:59.908816Z'
              }
            },
          ),
        ),
      ),
      201,
      request: request,
    );
  }
}
