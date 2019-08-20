import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:instagram_private_api/instagram_private_api.dart';
import 'package:instagram_private_api/src/core/insta_state.dart';
import 'package:instagram_private_api/src/utilities/response_interceptor.dart';

Future<void> main() async {
  final env = Platform.environment;
  final username = env['IG_USERNAME'];
  final password = env['IG_PASSWORD'];

  final StateStorage storage = FileStateStorage(username, 'test/state/');
  final InstaClient ig = InstaClient();
  ig.request.httpClient.interceptors.add(
      ResponseInterceptor(ig, (json) => storage.saveState(jsonEncode(json))));

  if (!await storage.exists()) {
    ig.state.init();
    await storage.createState();
    await ig.account.login(username, password);
  } else {
    ig.state = InstaState.fromJson(jsonDecode(await storage.loadState()));
  }

  print('logged in!');
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
  FutureOr<void> createState() => _stateFile.create(recursive: true);

  @override
  FutureOr<String> loadState() => _stateFile.readAsString();

  @override
  FutureOr<void> saveState(String encodedState) =>
      _stateFile.writeAsString(encodedState);

  @override
  FutureOr<bool> exists() => _stateFile.exists();
}

void jsonPrint(Object o) => print(jsonEncode(o));
