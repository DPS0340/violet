// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  test('Test Downloader', () async {
    var dio = Dio();

    var tests = [
      [
        'https://github.com/violet-dev/sync-data/releases/download/db_1642385595/data.db',
        't1.db'
      ],
      [
        'https://github.com/violet-dev/sync-data/releases/download/db_1642381015/data.db',
        't2.db'
      ],
      [
        'https://github.com/violet-dev/sync-data/releases/download/db_1642375243/data.db',
        't3.db'
      ],
    ];

    Future<void> runTask(String url, dynamic savePath) async {
      int nu = 0;
      int latest = 0;

      await dio.download(url, savePath, onReceiveProgress: (rec, total) {
        nu += rec - latest;
        latest = rec;

        if (nu <= 1024 * 1024) return;

        nu = 0;

        var progressString = '${((rec / total) * 100).toStringAsFixed(0)}%';
        print('$url [${rec ~/ 1024}/${total ~/ 1024}] $progressString');
      });
    }

    var t1 = runTask(tests[0][0], tests[0][1]);
    var t2 = runTask(tests[1][0], tests[1][1]);
    var t3 = runTask(tests[2][0], tests[2][1]);

    await Future.wait([t1, t2, t3]);
  });
}
