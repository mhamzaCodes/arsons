import 'dart:convert';

class OrderItemModel {
  final String id;
  final String orderId;
  final int srNo;
  final String size;
  final String gram;
  final String pipes;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.srNo,
    required this.size,
    required this.gram,
    required this.pipes,
  });

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    int? srNo,
    String? size,
    String? gram,
    String? pipes,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      srNo: srNo ?? this.srNo,
      size: size ?? this.size,
      gram: gram ?? this.gram,
      pipes: pipes ?? this.pipes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'sr_no': srNo,
      'size': size,
      'gram': gram,
      'pipes': pipes,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      srNo: int.tryParse(map['sr_no']?.toString() ?? '') ?? 0,
      size: map['size']?.toString() ?? '',
      gram: map['gram']?.toString() ?? '',
      pipes: map['pipes']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderItemModel.fromJson(String source) =>
      OrderItemModel.fromMap(json.decode(source));
}

class OrderModel {
  final String id;
  final String customerName;
  final String mobile;
  final String subtitle;
  final String orderTitle;
  final String date;
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.mobile,
    required this.subtitle,
    required this.orderTitle,
    required this.date,
    required this.createdAt,
    required this.items,
  });

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? mobile,
    String? subtitle,
    String? orderTitle,
    String? date,
    String? createdAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      mobile: mobile ?? this.mobile,
      subtitle: subtitle ?? this.subtitle,
      orderTitle: orderTitle ?? this.orderTitle,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'mobile': mobile,
      'subtitle': subtitle,
      'order_title': orderTitle,
      'date': date,
      'created_at': createdAt,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    var rawItems = map['items'];
    List<OrderItemModel> itemList = [];
    if (rawItems != null && rawItems is List) {
      itemList = rawItems
          .map((x) => OrderItemModel.fromMap(Map<String, dynamic>.from(x)))
          .toList();
    }

    return OrderModel(
      id: map['id']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      orderTitle: map['order_title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      items: itemList,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderModel.fromJson(String source) =>
      OrderModel.fromMap(json.decode(source));
}
