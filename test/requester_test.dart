import 'dart:convert';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart';

import 'package:jst_data/src/requester.dart';

class MockClient extends Mock implements Client {}

void main() {
  test('fetch()', () async {
    final mockClient = MockClient();

    final requester = Requester(
      partnerId: 'ywv5jGT8ge6Pvlq3FZSPol345asd',
      partnerKey: 'ywv5jGT8ge6Pvlq3FZSPol2323',
      token: '181ee8952a88f5a57db52587472c3798',
      url: 'https://c.jushuitan.com/api/open/query.aspx',
      client: mockClient,
    );

    when(
      mockClient.post(any, headers: anyNamed('headers')),
    ).thenAnswer(
        (_) async => Response.bytes(utf8.encode('{"test": "ok"}'), 200));

    await requester.fetch('shops.query', ts: '1608000837');

    verify(mockClient.post(
            Uri.parse('https://c.jushuitan.com/api/open/query.aspx?'
                'method=shops.query&partnerid=ywv5jGT8ge6Pvlq3FZSPol345asd&'
                'token=181ee8952a88f5a57db52587472c3798&ts=1608000837&'
                'sign=403697654caffbbfe21a841782b6af8f'),
            headers: anyNamed('headers')))
        .called(1);

    when(mockClient.post(any,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer(
            (_) async => Response.bytes(utf8.encode('{"success": "ok"}'), 200));

    final results = await requester.fetch('query2', body: {
      'param1': 'testParam1',
      'param2': 'testParam2',
    });

    expect(results['success'], 'ok');
    verify(
      mockClient.post(any,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: '{"param1":"testParam1","param2":"testParam2"}'),
    ).called(1);
  });
}
