// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/firebase_options.dart';
import 'package:poolmate/model/notification_model.dart';
import 'package:poolmate/utils/firestore/notification_utils.dart';

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Embedded service account JSON
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "bola-web-6448f",
  "private_key_id": "1a819cc90f64de6d1300f61ffd46b216e7182490",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDO1IbQNC/j2MvA\\nqfwJqaTQIEl4A3QgCfYdkqIeC2x0vl2TM4kCgJnXG92mjCPVwL8h6yvT/4tqxzSg\\ncyw21GLcBvkKlChxJhURw/S9fsRjWO4QOxmwP1sfbeWRAaiuoQ369pBlMPPWv6pJ\\nXJS5UKT3/GDFp4WhY+GEB/n66vkX4mZZpgiYsLM1/He9ucfRN3PNKj/LkxvtH6If\\nZGiBWfO0wOkNyFyi0+fkaciVdKnQtkZGuBocBClKXj0Jv3TPzhXlzu6x0H1zRBpa\\nebsiZ03l69bSSMkqR5L33ZEqkiaxbpqzIWA1nisjAwePT/m87Fq5kqwuhm37kmkF\\nV3Ivei51AgMBAAECggEAFX7ulPh7irNnN7qi9HEibTQR1qyLNuI6J0gsW7GFv9ti\\nF9CpGm65rmrZvju95LMP2ktaBoI+X+ZcwJk/vOIVdTcvTmtoCZxy36INT117tTSS\\np3KxAImRI6LVE11IBgA8lvrltnKgQQ8x+EZsOZdZUeGzwA8hWwzprQJ0N2EQ6uuf\\nkvLYUvxEPNJJwvStYrnI3hjBUCU9+AEeg95JH3gau8WK/FDZoy5k+m6Ksw0H2HTc\\n+7rSWce1oi6kb6QDO5IfShOALRj3jv8xqyP13sXATQvPc+BwzGV1DT/V/JyiuZR3\\nhPWAJNyAClFxBCxM1xm0T/0B1Nd6dymfKorK29LUCQKBgQD27/WM0gamJFgaFevL\\nrLhwDxjfZ4xNJWS1Ikae2k1WqLNe26vD3PKo2id++UAdrL9uQrY4M+z8dE7E0ZZ2\\nZV/lM56gMFVjFH9dTLiyLsV6vBbHH6+aCJXAcNNWfUGzl419FspwxzVU/s1prDFR\\nILL7gsUHplbRUPXMsdSqbz362QKBgQDWa8ANW6gdz0aNBaWf7oSS3FjnaKNYLmY8\\npBXUVfrDLn0x4GiJ7P7A99dylWc00mgW3QxubsE//V+MlGoFOZDu7KjtBC1Je/P8\\nYY3YDe12L6AkULjS8Sm177o69friZo4Am3vZYjBjQFVAKjy8RVhRJASDlcoaO3OC\\nNTzgShu2/QKBgQDsJ1GqSZUoQGutDrfAwb5lFFsSE8H+aTtlapElC9qYfJ+FoQkk\\nN+ItDuxkptPlTTaJqO0A1M/YIxbNbS66rXpHBNW3lmGibpDbVirv5IDhPo1+AtR5\\nt6oXLw89kG5L5SzfqvMRZcGgNkmVvKIxVtc0Zrws86vlY8qd5pdeIyKgCQKBgBsv\\nXBEVftIQtnworCADyJEqGKd2L8d9Un77urzKDdnzKfJJ5lceUgo7IfioEoay6nmD\\nmxDhP+USBaw4INz6uHJiVOR/9BHuAjgMUkSDN4kVbrNL/LLZ2pTziOPyzdUodXaE\\nQAaGmWXsASL6d+rSy+i1rVDVi+MZiIKIp2g0XSEtAoGAfLfnW/RhO3ERLcuhBD3p\\nsD/HCG2UfMOy4QTU7ZGu5TdCJ9xagxg/4H4lys8XssOHopatC9OeOQEMVmtabNsf\\n3bnkdLkgGe+qh0c98ScEWQp1xzhz4w4777uDbxlIEcLAJT5C6qI4ib5AhBCgk+Rf\\n3y4qbgrzCaNKTUJRjL+nJLA=\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@bola-web-6448f.iam.gserviceaccount.com",
  "client_id": "116245465003421142646",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40bola-web-6448f.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  static Future getCharacters() {
    return http.get(Uri.parse(Constant.jsonNotificationFileURL.toString()));
  }

  static Future<String> getAccessToken() async {
    try {
      debugPrint('Attempting to get access token...');

      Map<String, dynamic> jsonData = {};

      // Try embedded service account first
      if (_serviceAccountJson.isNotEmpty) {
        debugPrint('Using embedded service account...');
        jsonData = json.decode(_serviceAccountJson);
      }
      // Fallback to external URL if configured
      else if (Constant.jsonNotificationFileURL.isNotEmpty) {
        debugPrint('Using external service account URL...');
        final response = await getCharacters();
        jsonData = json.decode(response.body);
      }
      // No service account configured
      else {
        debugPrint('No service account configured. Cannot get access token.');
        return '';
      }

      debugPrint('Service account project_id: ${jsonData['project_id']}');

      final serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(jsonData);
      final client =
          await clientViaServiceAccount(serviceAccountCredentials, _scopes);

      final accessToken = client.credentials.accessToken.data;
      debugPrint(
          'Successfully obtained access token (length: ${accessToken.length})');

      return accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return '';
    }
  }

  static sendOneNotification(
      {required String type,
      required String token,
      required Map<String, dynamic> payload}) async {
    try {
      debugPrint("Attempting to send notification...");
      debugPrint("Type: $type, Token: $token");
      debugPrint("Payload: $payload");

      final String accessToken = await getAccessToken();
      if (accessToken.isEmpty) {
        debugPrint('Failed to get access token');
        return false;
      }

      debugPrint("accessToken=======>");
      debugPrint(
          "Access token obtained successfully (length: ${accessToken.length})");

      NotificationModel? notificationModel =
          await NotificationUtils.getNotificationContent(type);

      if (notificationModel == null) {
        debugPrint('No notification template found for type: $type');
        return false;
      }

      // Use project ID from Firebase options as fallback if senderId is empty
      String projectId = Constant.senderId.isNotEmpty
          ? Constant.senderId
          : DefaultFirebaseOptions.currentPlatform.projectId;

      debugPrint("Using project ID: $projectId");

      final notificationPayload = {
        'message': {
          'token': token,
          'notification': {
            'body': notificationModel.message ?? '',
            'title': notificationModel.subject ?? ''
          },
          'data': payload,
          'android': {
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
            },
            'priority': 'HIGH',
          },
          'apns': {
            'headers': {
              'apns-push-type': 'alert',
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': notificationModel.subject ?? '',
                  'body': notificationModel.message ?? '',
                },
                'sound': 'default',
              },
            },
          },
        }
      };

      debugPrint("------>");
      debugPrint("$notificationModel");

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(notificationPayload),
      );

      debugPrint("Notification Response=======>");
      debugPrint("this is the token $token");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
        return true;
      } else {
        debugPrint(
            'Failed to send notification. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  static sendChatNotification(
      {required String token,
      required String title,
      required String body,
      required Map<String, dynamic> payload}) async {
    try {
      debugPrint("=== SENDING CHAT NOTIFICATION ===");
      debugPrint("Token: $token");
      debugPrint("Title: $title");
      debugPrint("Body: $body");
      debugPrint("Payload: $payload");

      final String accessToken = await getAccessToken();
      if (accessToken.isEmpty) {
        debugPrint('Failed to get access token - notification cannot be sent');
        return false;
      }

      debugPrint("Successfully obtained access token");

      // Use project ID from Firebase options as fallback if senderId is empty
      String projectId = Constant.senderId.isNotEmpty
          ? Constant.senderId
          : DefaultFirebaseOptions.currentPlatform.projectId;

      debugPrint("Using project ID: $projectId");

      final bool isSosAlert = payload['type'] == 'sos_alert';
      final String androidChannelId =
          isSosAlert ? 'sos_channel' : 'high_importance_channel';
      final String androidSound = isSosAlert ? 'sos_43210' : 'default';
      final Map<String, dynamic> apnsSound = isSosAlert
          ? {
              'critical': 1,
              'name': 'sos_43210.mp3',
              'volume': 1.0,
            }
          : {
              'name': 'default',
            };

      final notificationPayload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            ...payload,
            // Ensure background handlers run on iOS
            'content_available': 'true',
          },
          'android': {
            'notification': {
              'channel_id': androidChannelId,
              'sound': androidSound,
            },
            'priority': 'HIGH',
          },
          'apns': {
            'headers': {
              'apns-push-type': 'alert',
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': apnsSound,
                'content-available': 1,
                'category': isSosAlert ? 'sos_alert' : 'default',
              },
            },
          },
        }
      };

      debugPrint("Notification payload: ${jsonEncode(notificationPayload)}");

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(notificationPayload),
      );

      debugPrint("=== NOTIFICATION RESPONSE ===");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Headers: ${response.headers}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint('✅ Chat notification sent successfully!');
        return true;
      } else {
        debugPrint('❌ Failed to send chat notification');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception sending chat notification: $e');
      return false;
    }
  }
}
