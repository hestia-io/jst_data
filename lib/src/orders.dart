import 'package:logging/logging.dart';
import 'package:uniform_data/uniform_data.dart';
import 'package:uniform_data/page_token.dart';

import 'requester.dart';

final Logger _logger = Logger('jst.orders');

class Orders {
  Orders({
    this.requester,
  });

  static final String listUrl = 'orders.out.simple.query';

  final Requester requester;

  Future<OrderListResponse> list(
    String part, {
    String pageToken,
    int maxResults = 30,
    String shippedBefore,
    String shippedAfter,
  }) async {
    maxResults ??= 30;
    final pageIndex = IndexPageToken.decode(pageToken, 1);

//_logger.info('pageIndex: $pageIndex, maxResults: $maxResults');

    final results = await requester.fetch(listUrl, body: {
      'status': 'Confirmed',
      // 时间间隔不螚超过7天
      'modified_begin': shippedAfter,
      'modified_end': shippedBefore,
      'page_index': '$pageIndex',
      'page_size': '$maxResults',
    });

    final orders = (results['datas'] ?? []).map<Order>((e) {
      final order = Order()
        ..id = e['o_id']?.toString() ?? ''
        ..kind = 'jst#order';

      if (part.contains('snippet')) {
        order.snippet = (OrderSnippet()
          ..merchantId = e['shop_id']?.toString() ?? ''
          ..merchantOrderId = e['so_id']?.toString() ?? ''
          ..customerId = e['shop_buyer_id']?.toString() ?? ''
          ..placedDate = e['io_date']?.toString() ?? ''
          ..lineItems.addAll((e['items'] ?? []).map<OrderLineItem>((item) {
            return OrderLineItem()
              ..id = item['ioi_id']?.toString() ?? ''
              ..product = (OrderLineItemProduct()
                ..id = item['sku_id']?.toString() ?? ''
                ..title = item['name']?.toString() ?? ''
                ..price = (Price()
                  ..currency = 'RMB'
                  ..value = item['sale_price']?.toString() ?? ''))
              ..quantityShipped = item['qty'] ?? 0
              ..shippingDetails = (OrderLineItemShippingDetails()
                ..warehouseId = e['wms_co_id']?.toString() ?? '');
          }).toList()));
      }

      if (part.contains('status')) {
        order.status = (OrderStatus()..orderStatus = OrderOrderStatus.shipped);
      }

      if (part.contains('contentDetails')) {
        order.contentDetails = (OrderContentDetails()
          ..customAttributes.add(CustomAttribute()
            ..name = 'note'
            ..value = (e['remark'] ?? '').toString()));
      }

      return order;
    });

    final pageInfo = PageInfo()
      ..totalResults = results['data_count']
      ..resultsPerPage = maxResults;

    final response = OrderListResponse()
      ..kind = 'jst#orderListResponse'
      ..pageInfo = pageInfo
      ..items.addAll(orders);

    final currentPage = results['page_index'];
    final totalPage = results['page_count'];

    if (currentPage > 1) {
      response.prevPageToken = IndexPageToken.encode(pageIndex - 1);
    }

    if (currentPage < totalPage) {
      response.nextPageToken = IndexPageToken.encode(pageIndex + 1);
    }

    return response;

    /* 订单与出库单比较
    shippedBefore = '2021-03-29 12:00:00';
    shippedAfter = '2021-03-29 06:00:00';

    final results = await requester.fetch('orders.out.simple.query', body: {
      'status': 'Confirmed',
      'modified_begin': shippedAfter,
      'modified_end': shippedBefore,
      'page_index': '1',
      'page_size': '50',
    });

    print(results['data_count']);

    results['datas'].forEach((e) => print([e['so_id'], e['wms_co_id']]));

    print('=======================');

    final results2 = await requester.fetch('orders.single.query', body: {
      'status': 'Sent',
      'modified_begin': shippedAfter,
      'modified_end': shippedBefore,
      'page_index': '1',
      'page_size': '50',
    });

    print(results2['data_count']);

    results2['orders'].forEach((e) {
      print([e['so_id'], e['wms_co_id']]);
      print(e);
    });
    */
  }
}
