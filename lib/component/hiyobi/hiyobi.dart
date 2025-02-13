// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';

import 'package:tuple/tuple.dart';
import 'package:violet/network/wrapper.dart' as http;

class HiyobiManager {
  // [Thumbnail Image], [Image List]
  static Future<Tuple2<String, List<String>>> getImageList(String id) async {
    final gg = await http.get('https://api.hiyobi.me/gallery/$id');
    final urls = gg.body;
    final json = jsonDecode(urls) as Map<String, dynamic>;
    final files = json['files'];
    final result = <String>[];
    final isWebp = json['iswebp'] as bool;

    files.forEach((value) {
      final item = value as Map<String, dynamic>;
      if (isWebp && item['haswebp'] == 1 && item.containsKey('hash')) {
        result.add('https://cdn.hiyobi.me/data/$id/${item['hash']}.webp');
      } else {
        result.add('https://cdn.hiyobi.me/data/$id/${item['name']}');
      }
    });

    return Tuple2<String, List<String>>(
        'https://tn.hiyobi.me/tn/$id.jpg', result);
  }

  static Future<List<Tuple3<DateTime, String, String>>> getComments(
      String id) async {
    final gg = await http.get('https://api.hiyobi.me/gallery/$id/comments');
    final comments = jsonDecode(gg.body) as List<dynamic>;

    return comments
        .map((e) => Tuple3<DateTime, String, String>(
            DateTime.fromMillisecondsSinceEpoch((e['date'] as int) * 1000),
            e['name'],
            e['comment']))
        .toList();
  }
}
