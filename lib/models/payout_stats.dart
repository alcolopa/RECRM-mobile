class PayoutSummary {
  final double totalSales;
  final double totalCommissions;
  final double agentPayouts;
  final double totalProfit;

  PayoutSummary({
    required this.totalSales,
    required this.totalCommissions,
    required this.agentPayouts,
    required this.totalProfit,
  });

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalCommissions: (json['totalCommissions'] ?? 0).toDouble(),
      agentPayouts: (json['agentPayouts'] ?? 0).toDouble(),
      totalProfit: (json['totalProfit'] ?? 0).toDouble(),
    );
  }
}

class AgentPayoutStats {
  final String id;
  final String name;
  final String? email;
  final double totalSales;
  final double pendingPayout;
  final double paidPayout;
  final List<PayoutDeal> deals;

  AgentPayoutStats({
    required this.id,
    required this.name,
    this.email,
    required this.totalSales,
    required this.pendingPayout,
    required this.paidPayout,
    required this.deals,
  });

  factory AgentPayoutStats.fromJson(Map<String, dynamic> json) {
    return AgentPayoutStats(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      pendingPayout: (json['pendingPayout'] ?? 0).toDouble(),
      paidPayout: (json['paidPayout'] ?? 0).toDouble(),
      deals: (json['deals'] as List? ?? [])
          .map((d) => PayoutDeal.fromJson(d))
          .toList(),
    );
  }
}

class PayoutDeal {
  final String id;
  final String title;
  final double? value;
  final double? agentCommission;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  PayoutDeal({
    required this.id,
    required this.title,
    this.value,
    this.agentCommission,
    required this.isPaid,
    this.paidAt,
    required this.createdAt,
  });

  factory PayoutDeal.fromJson(Map<String, dynamic> json) {
    return PayoutDeal(
      id: json['id'],
      title: json['title'],
      value: json['value'] != null ? (json['value']).toDouble() : null,
      agentCommission: json['agentCommission'] != null ? (json['agentCommission']).toDouble() : null,
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class AdminPayoutStats {
  final PayoutSummary summary;
  final List<AgentPayoutStats> agents;

  AdminPayoutStats({
    required this.summary,
    required this.agents,
  });

  factory AdminPayoutStats.fromJson(Map<String, dynamic> json) {
    return AdminPayoutStats(
      summary: PayoutSummary.fromJson(json['summary']),
      agents: (json['agents'] as List? ?? [])
          .map((a) => AgentPayoutStats.fromJson(a))
          .toList(),
    );
  }
}

class PersonalPayoutStats {
  final double totalSales;
  final double targetSales;
  final double totalEarned;
  final double pendingPayout;
  final double totalPaid;
  final List<PayoutDeal> deals;

  PersonalPayoutStats({
    required this.totalSales,
    required this.targetSales,
    required this.totalEarned,
    required this.pendingPayout,
    required this.totalPaid,
    required this.deals,
  });

  factory PersonalPayoutStats.fromJson(Map<String, dynamic> json) {
    return PersonalPayoutStats(
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      targetSales: (json['targetSales'] ?? 0).toDouble(),
      totalEarned: (json['totalEarned'] ?? 0).toDouble(),
      pendingPayout: (json['pendingPayout'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      deals: (json['deals'] as List? ?? [])
          .map((d) => PayoutDeal.fromJson(d))
          .toList(),
    );
  }
}
