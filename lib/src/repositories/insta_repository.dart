import 'package:instagram_private_api/src/core/insta_client.dart';

abstract class InstaRepository {
  InstaClient client;
  InstaRepository(this.client);
}