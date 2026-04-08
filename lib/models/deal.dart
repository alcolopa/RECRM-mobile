class Deal {
  final String id;
  final String title;
  final double? value;
  final String stage; // DealStage enum
  final String organizationId;
  final String? contactId;
  final String? leadId;
  final String? propertyId;
  final String? assignedUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String type; // DealType enum
  final double? propertyPrice;
  final double? rentPrice;
  final double? buyerCommission;
  final double? sellerCommission;
  final double? totalCommission;
  final double? agentCommission;
  final bool isAgentPaid;
  final DateTime? agentPaidAt;

  Deal({
    required this.id,
    required this.title,
    this.value,
    required this.stage,
    required this.organizationId,
    this.contactId,
    this.leadId,
    this.propertyId,
    this.assignedUserId,
    required this.createdAt,
    required this.updatedAt,
    this.type = 'SALE',
    this.propertyPrice,
    this.rentPrice,
    this.buyerCommission,
    this.sellerCommission,
    this.totalCommission,
    this.agentCommission,
    this.isAgentPaid = false,
    this.agentPaidAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'],
      title: json['title'],
      value: json['value'] != null
          ? double.parse(json['value'].toString())
          : null,
      stage: json['stage'],
      organizationId: json['organizationId'],
      contactId: json['contactId'],
      leadId: json['leadId'],
      propertyId: json['propertyId'],
      assignedUserId: json['assignedUserId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      type: json['type'] ?? 'SALE',
      propertyPrice: json['propertyPrice'] != null
          ? double.parse(json['propertyPrice'].toString())
          : null,
      rentPrice: json['rentPrice'] != null
          ? double.parse(json['rentPrice'].toString())
          : null,
      buyerCommission: json['buyerCommission'] != null
          ? double.parse(json['buyerCommission'].toString())
          : null,
      sellerCommission: json['sellerCommission'] != null
          ? double.parse(json['sellerCommission'].toString())
          : null,
      totalCommission: json['totalCommission'] != null
          ? double.parse(json['totalCommission'].toString())
          : null,
      agentCommission: json['agentCommission'] != null
          ? double.parse(json['agentCommission'].toString())
          : null,
      isAgentPaid: json['isAgentPaid'] ?? false,
      agentPaidAt: json['agentPaidAt'] != null
          ? DateTime.parse(json['agentPaidAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'stage': stage,
      'organizationId': organizationId,
      'contactId': contactId,
      'leadId': leadId,
      'propertyId': propertyId,
      'assignedUserId': assignedUserId,
      'type': type,
      'propertyPrice': propertyPrice,
      'rentPrice': rentPrice,
      'buyerCommission': buyerCommission,
      'sellerCommission': sellerCommission,
      'totalCommission': totalCommission,
      'agentCommission': agentCommission,
      'isAgentPaid': isAgentPaid,
    };
  }
}
