import 'package:brisk/constants/download_command.dart';
import 'package:brisk/downloader/http_download_request.dart';
import 'package:brisk/model/isolate/download_isolator_args.dart';
import 'package:brisk/model/isolate/isolate_method_args.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../util/http_util.dart';

class SingleConnectionManager {
  static final Map<int, Map<int, HttpDownloadRequest>> _connections = {};

  static void handleSingleConnection(HandleSingleConnectionArgs args) async {
    final channel = IsolateChannel.connectSend(args.sendPort);
    channel.stream.listen((data) {
      if (data is SegmentedDownloadIsolateArgs) {
        final id = data.downloadItem.id;
        _connections[id] ??= {};
        final segmentNumber = data.segmentNumber ?? args.segmentNumber;
        HttpDownloadRequest? request = _connections[id]![segmentNumber];
        if (request == null) {
          final startEndByte = calculateByteStartAndByteEnd(
            args.totalSegments,
            segmentNumber,
            data.downloadItem.contentLength,
          );
          request = HttpDownloadRequest(
            downloadItem: data.downloadItem,
            baseTempDir: data.baseTempDir,
            segmentNumber: segmentNumber,
            startByte: startEndByte[0],
            endByte: startEndByte[1],
            totalSegments: args.totalSegments,
            connectionRetryTimeoutMillis: args.connectionRetryTimeout,
            maxConnectionRetryCount: args.maxConnectionRetryCount,
          );
          _connections[id]![segmentNumber] = request;
        }

        switch (data.command) {
          case DownloadCommand.start:
            request.start(channel.sink.add);
            break;
          case DownloadCommand.pause:
            request.pause(channel.sink.add);
            break;
          case DownloadCommand.clearConnections:
            _connections[id]?.clear();
            break;
          case DownloadCommand.cancel:
            request.cancel();
            _connections[id]?.clear();
            break;
          case DownloadCommand.forceCancel:
            request.cancel(failure: true);
            _connections[id]?.clear();
            break;
        }
      }
    });
  }
}
