import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:uniform_data/uniform_data.dart';

import 'package:jst_data/src/orders.dart';
import 'package:jst_data/src/requester.dart';

class MockRequester extends Mock implements Requester {}

void main() {
  var requester;
  var orders;

  setUp(() {
    requester = MockRequester();
    orders = Orders(requester: requester);
  });

  test('list()', () async {
    final start = '2021-01-10T00:00:00Z';
    final end = '2021-01-20T00:00:00Z';

    when(requester.fetch(Orders.listUrl, body: {
      'status': 'Confirmed',
      'modified_begin': start,
      'modified_end': end,
      'page_index': '1',
      'page_size': '30',
    })).thenAnswer((_) async {
      return {
        'page_index': 1,
        'page_count': 3,
        'data_count': 80,
        'datas': List.generate(30, (i) {
          return {
            'o_id': 'testOrderId_$i',
            'shop_id': 'testShopId_$i',
            'so_id': 'testShopOrderId_$i',
            'wms_co_id': 'testWarehouseId_$i',
            'items': List.generate(i, (j) {
              return {
                'ioi_id': 'testLineItemId_$j',
                'sku_id': 'testSkuId_$j',
                'sale_price': j * 10,
                'qty': j,
              };
            }),
          };
        }),
      };
    });

    final response = await orders.list('snippet,status',
        shippedAfter: start, shippedBefore: end);

    expect(response.items.length, 30);
    expect(response.kind, 'jst#orderListResponse');
    expect(response.pageInfo.totalResults, 80);
    expect(response.pageInfo.resultsPerPage, 30);
    expect(response.hasPrevPageToken(), false);
    expect(response.hasNextPageToken(), true);

    List.generate(30, (i) {
      final order = response.items[i];
      expect(order.id, 'testOrderId_$i');
      expect(order.kind, 'jst#order');

      final snippet = order.snippet;
      expect(snippet.merchantId, 'testShopId_$i');
      expect(snippet.merchantOrderId, 'testShopOrderId_$i');

      List.generate(i, (j) {
        final lineItem = snippet.lineItems[j];
        expect(lineItem.id, 'testLineItemId_$j');
        expect(lineItem.product.id, 'testSkuId_$j');
        expect(lineItem.product.price.value, '${j * 10}');
        expect(lineItem.product.price.currency, 'RMB');
        expect(lineItem.quantityShipped, j);
        expect(lineItem.shippingDetails.warehouseId, 'testWarehouseId_$i');
      });

      final status = order.status;
      expect(status.orderStatus, OrderOrderStatus.shipped);
    });
  });
}
