import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image/image.dart';
import 'package:instagram_private_api/instagram_private_api.dart';
import 'package:instagram_private_api/src/core/insta_state.dart';
import 'package:instagram_private_api/src/types/timeline_media_types.dart';
import 'package:instagram_private_api/src/utilities/response_interceptor.dart';
import 'package:instagram_private_api/src/utilities/time.dart';
import 'package:instagram_private_api/src/utilities/video_utility.dart';

import 'create_response.dart';

void main() {
  mainAsync().then((_) => print('done'));
}

void saveJsonAsResponse(Map<String, dynamic> json) {}

Future mainAsync() async {
  final env = Platform.environment;
  final username = env['IG_USERNAME'];
  final password = env['IG_PASSWORD'];

  final cookiesFile = File('test/state/state_$username.json');
  // ignore: avoid_slow_async_io
  final cookiesExist = await cookiesFile.exists();

  InstaClient ig;

  if (!cookiesExist) {
    ig = InstaClient();
    ig.state.init();
    await cookiesFile.create(recursive: true);
  } else {
    ig = InstaClient(
        state:
            InstaState.fromJson(jsonDecode(await cookiesFile.readAsString())));
  }
  ig.request.httpClient.interceptors.add(ResponseInterceptor(
      ig, (json) => cookiesFile.writeAsString(jsonEncode(json))));

  if (!cookiesExist) {
    print(jsonEncode(await ig.account.login(username, password)));
  }
  print('logged in!');
  try {

  } catch (e) {
    print(e);
  }

  print('done!');
}

void jsonPrint(Object o) => print(jsonEncode(o));
