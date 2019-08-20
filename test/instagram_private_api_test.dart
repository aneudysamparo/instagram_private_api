import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';
import 'package:instagram_private_api/instagram_private_api.dart';
import 'package:instagram_private_api/src/core/insta_state.dart';
import 'package:instagram_private_api/src/utilities/response_interceptor.dart';
import 'package:instagram_private_api/src/utilities/time.dart';
import 'package:instagram_private_api/src/utilities/video_utility.dart';

import 'create_response.dart';

Future<void> main() async {
  final env = Platform.environment;
  final username = env['IG_USERNAME'];
  final password = env['IG_PASSWORD'];

  final StateStorage storage = FileStateStorage(username, 'test/state');
  final bool storageExists = await storage.exists();
  final InstaClient ig = InstaClient(
      state: storageExists
          ? InstaState.fromJson(jsonDecode(await storage.loadState()))
          : null);
  ig.request.httpClient.interceptors.add(
      ResponseInterceptor(ig, (json) => storage.saveState(jsonEncode(json))));

  if (!storageExists) {
    ig.state.init();
    await storage.createState();
    await ig.account.login(username, password);
  }
  print('logged in!');

  try {
    //for testing
  } catch (e) {
    print(e);
  }
}

mixin StateStorage {
  FutureOr<bool> exists();

  FutureOr<void> createState();

  FutureOr<String> loadState();

  FutureOr<void> saveState(String encodedState);
}

class FileStateStorage implements StateStorage {
  File _stateFile;

  FileStateStorage(String username, [String stateFolder = '']) {
    _stateFile = File('$stateFolder/state_$username.json');
  }

  @override
  FutureOr<void> createState() async =>
      await _stateFile.create(recursive: true);

  @override
  FutureOr<String> loadState() async => await _stateFile.readAsString();

  @override
  FutureOr<void> saveState(String encodedState) async =>
      await _stateFile.writeAsString(encodedState);

  @override
  FutureOr<bool> exists() async => await _stateFile.exists();
}

void jsonPrint(Object o) => print(jsonEncode(o));
