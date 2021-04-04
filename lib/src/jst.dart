import 'package:http/http.dart';

import 'requester.dart';
import 'orders.dart';

class Jst {
  Jst({
    String partnerId,
    String partnerKey,
    String token,
    String url = 'https://open.erp321.com/api/open/query.aspx',
    Client client,
  }) {
    _client = Client();

    _requester = Requester(
      partnerId: partnerId,
      partnerKey: partnerKey,
      token: token,
      url: url,
      client: _client,
    );

    _orders = Orders(requester: _requester);
  }

  Client _client;

  Requester _requester;

  Orders _orders;

  Orders get orders => _orders;

  Future<Map> fetch(String method, {Map body}) {
    return _requester.fetch(method, body: body);
  }

  Future<void> dispose() async {
    _client.close();
  }
}
