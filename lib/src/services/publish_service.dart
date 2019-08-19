import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart';
import 'package:instagram_private_api/src/core/insta_client.dart';
import 'package:instagram_private_api/src/responses/media/configure_response.dart';
import 'package:instagram_private_api/src/responses/media/configure_video_response.dart';
import 'package:instagram_private_api/src/services/insta_service.dart';
import 'package:instagram_private_api/src/types/timeline_media_types.dart';
import 'package:instagram_private_api/src/utilities/time.dart';
import 'package:instagram_private_api/src/utilities/video_utility.dart';
import 'package:meta/meta.dart';

class PublishService extends InstaService {
  PublishService(InstaClient client) : super(client);

  Future<MediaConfigureResponse> photo({
    @required Uint8List photo,

    /// for ig.upload
    String id,
    int uploadTries = 1,
    int quality = 80,
    List<String> sharingUserIds,

    /// for ig.media
    String caption = '',
    List<double> cropCenter,
    double cropZoom = 1.0,
    String mediaFolder,
    MediaLocation location,
    List<Usertag> usertags, // only as List<>, as only 'in' is supported
  }) async {
    final jpegData = JpegData()..read(photo);

    final uploadId = id ?? utcNow().floor().toString();
    int tried = 0;
    while (++tried < uploadTries) {
      try {
        await client.upload.photo(photo,
            id: uploadId,
            numReupload: tried - 1,
            quality: quality,
            sharingUserIds: sharingUserIds);
        break;
      } catch (err) {
        // ignore: avoid_catches_without_on_clauses
        if (tried >= uploadTries) {
          rethrow;
        }
      }
    }
    return client.media.configure(
        uploadId: uploadId,
        width: jpegData.width,
        height: jpegData.height,
        usertags: usertags != null ? (Usertags()..usertagsIn = usertags) : null,
        location: location,
        caption: caption,
        cropCenter: cropCenter,
        cropZoom: cropZoom,
        mediaFolder: mediaFolder);
  }

  Future<MediaConfigureVideoResponse> video(
      {@required Uint8List video,
      @required Uint8List posterFrame,

      /// for ig.upload
      String id,
      List<String> sharingUserIds,
      int uploadTries = 1,
      Duration transcodeDelay,

      /// for ig.media
      String caption = '',
      MediaLocation location,
      Usertags usertags,
      bool audioMuted = false,
      int posterFrameIndex = 0}) async {
    final videoInfo = VideoData(video);
    final jpegData = JpegData()..read(posterFrame);
    final uploadId = id ?? utcNow().floor().toString();
    int tried = 0;
    while ((tried++) <= uploadTries) {
      try {
        await client.upload.video(video, videoInfo.width, videoInfo.height,
            videoInfo.duration.floor(),
            id: uploadId,
            numReupload: tried - 1,
            sharingUserIds: sharingUserIds);
      } catch (err) {
        if (tried >= uploadTries) {
          rethrow;
        }
      }
    }
    tried = 0;
    while ((tried++) <= uploadTries) {
      try {
        await client.upload.photo(posterFrame,
            id: uploadId,
            numReupload: tried - 1,
            sharingUserIds: sharingUserIds);
      } catch (err) {
        if (tried >= uploadTries) {
          rethrow;
        }
      }
    }
    try {
      await client.media.uploadFinish(
          uploadId: uploadId,
          width: videoInfo.width,
          height: videoInfo.height,
          videoLength: videoInfo.duration / 1000.0);
    } on DioError catch (err) {
      if (err.response != null && err.response.statusCode == 202) {
        /// resolve transcode-errors using a delay
        await Future.delayed(transcodeDelay ?? Duration(seconds: 5));
      }
    }
    return client.media.configureVideo(
        uploadId: uploadId,
        video: videoInfo,
        caption: caption,
        location: location,
        usertags: usertags,
        audioMuted: audioMuted,
        posterFrameIndex: posterFrameIndex);
  }
}
