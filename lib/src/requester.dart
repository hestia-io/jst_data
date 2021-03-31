import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart';

final _logger = Logger('jst.requester');

class Requester {
  Requester({
    this.partnerId,
    this.partnerKey,
    this.token,
    this.url = 'https://open.erp321.com/api/open/query.aspx',
    this.client,
  });

  /// 合作商 ID
  final String partnerId;

  /// 合作商 Key
  final String partnerKey;

  /// 合作商 Token
  final String token;

  /// 接口地址
  final String url;

  /// http client
  final Client client;

  /// 请求 聚水潭 接口
  /// 调用规则见文档 https://open.jushuitan.com/document/8.html
  Future<Map> fetch(
    String method, {
    Map body,
    String ts,
  }) async {
    final params = {
      'token': token,
      'ts': ts ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    final sign = _generateSign(method, params);

    final pstr = params.keys
        .map<String>((String key) => '$key=${params[key]}')
        .join('&');

    final r = Uri.parse('$url?method=$method&partnerid=$partnerId'
        '&$pstr&sign=$sign');

    _logger.info(r, body);

    final response = await client.post(r,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body == null ? null : jsonEncode(body));

    //_logger.info(response.body);

    return jsonDecode(response.body);
  }

  /// 生成签名
  String _generateSign(String method, Map<String, String> params) {
    final pstr =
        params.keys.map<String>((key) => '$key${params[key]}').join('');
    final str = '$method$partnerId$pstr$partnerKey';
    return md5.convert(utf8.encode(str)).toString();
  }
}
