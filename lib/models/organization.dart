class Organization {
  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? email;
  final String? logo;
  final String? phone;
  final String? website;
  final String ownerId;
  final String accentColor;
  final String defaultTheme; // OrganizationTheme enum: LIGHT, DARK
  final List<Membership>? memberships;
  final Subscription? subscription;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.email,
    this.logo,
    this.phone,
    this.website,
    required this.ownerId,
    this.accentColor = 'EMERALD',
    this.defaultTheme = 'LIGHT',
    this.memberships,
    this.subscription,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      address: json['address'],
      email: json['email'],
      logo: json['logo'],
      phone: json['phone'],
      website: json['website'],
      ownerId: json['ownerId'],
      accentColor: json['accentColor'] ?? 'EMERALD',
      defaultTheme: json['defaultTheme'] ?? 'LIGHT',
      memberships: json['memberships'] != null
          ? (json['memberships'] as List)
              .map((i) => Membership.fromJson(i))
              .toList()
          : null,
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
      'email': email,
      'logo': logo,
      'phone': phone,
      'website': website,
      'ownerId': ownerId,
      'accentColor': accentColor,
      'defaultTheme': defaultTheme,
    };
  }
}

class Membership {
  final String id;
  final String role; // UserRole enum: OWNER, ADMIN, AGENT, SUPPORT
  final String userId;
  final String organizationId;
  final String? customRoleId;
  final CustomRole? customRole;
  final User? user;

  Membership({
    required this.id,
    required this.role,
    required this.userId,
    required this.organizationId,
    this.customRoleId,
    this.customRole,
    this.user,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'],
      role: json['role'],
      userId: json['userId'],
      organizationId: json['organizationId'],
      customRoleId: json['customRoleId'],
      customRole: json['customRole'] != null
          ? CustomRole.fromJson(json['customRole'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class CustomRole {
  final String id;
  final String name;
  final String? description;
  final List<String> permissions;
  final int level;
  final bool isSystem;

  CustomRole({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const [],
    this.level = 1,
    this.isSystem = false,
  });

  factory CustomRole.fromJson(Map<String, dynamic> json) {
    return CustomRole(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      permissions: List<String>.from(json['permissions'] ?? []),
      level: json['level'] ?? 1,
      isSystem: json['isSystem'] ?? false,
    );
  }
}

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? phone;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatar: json['avatar'],
      phone: json['phone'],
    );
  }

  String get fullName => '$firstName $lastName'.trim().isNotEmpty
      ? ('$firstName $lastName').trim()
      : email.split('@')[0];
}

class Invitation {
  final String id;
  final String email;
  final String role;
  final String status; // PENDING, ACCEPTED, EXPIRED
  final DateTime expiresAt;
  final String? customRoleId;
  final CustomRole? customRole;

  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
    this.customRoleId,
    this.customRole,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      expiresAt: DateTime.parse(json['expiresAt']),
      customRoleId: json['customRoleId'],
      customRole: json['customRole'] != null
          ? CustomRole.fromJson(json['customRole'])
          : null,
    );
  }
}

class Subscription {
  final String id;
  final String status;
  final int seats;
  final int usedSeats;
  final DateTime trialEndDate;

  Subscription({
    required this.id,
    required this.status,
    required this.seats,
    required this.usedSeats,
    required this.trialEndDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      status: json['status'],
      seats: json['seats'] ?? 1,
      usedSeats: json['usedSeats'] ?? 0,
      trialEndDate: DateTime.parse(json['trialEndDate']),
    );
  }
}

class CommissionConfig {
  final String? id;
  final String? organizationId;
  
  // RENT
  final double? rentBuyerValue;
  final String rentBuyerType;
  final double? rentSellerValue;
  final String rentSellerType;
  final double? rentAgentValue;
  final String rentAgentType;

  // SALE
  final double? saleBuyerValue;
  final String saleBuyerType;
  final double? saleSellerValue;
  final String saleSellerType;
  final double? saleAgentValue;
  final String saleAgentType;

  final String? paymentTiming;
  final String? paymentMethod;

  CommissionConfig({
    this.id,
    this.organizationId,
    this.rentBuyerValue,
    this.rentBuyerType = 'MULTIPLIER',
    this.rentSellerValue,
    this.rentSellerType = 'MULTIPLIER',
    this.rentAgentValue,
    this.rentAgentType = 'PERCENTAGE',
    this.saleBuyerValue,
    this.saleBuyerType = 'PERCENTAGE',
    this.saleSellerValue,
    this.saleSellerType = 'PERCENTAGE',
    this.saleAgentValue,
    this.saleAgentType = 'PERCENTAGE',
    this.paymentTiming,
    this.paymentMethod,
  });

  factory CommissionConfig.fromJson(Map<String, dynamic> json) {
    return CommissionConfig(
      id: json['id'],
      organizationId: json['organizationId'],
      rentBuyerValue: (json['rentBuyerValue'] as num?)?.toDouble(),
      rentBuyerType: json['rentBuyerType'] ?? 'MULTIPLIER',
      rentSellerValue: (json['rentSellerValue'] as num?)?.toDouble(),
      rentSellerType: json['rentSellerType'] ?? 'MULTIPLIER',
      rentAgentValue: (json['rentAgentValue'] as num?)?.toDouble(),
      rentAgentType: json['rentAgentType'] ?? 'PERCENTAGE',
      saleBuyerValue: (json['saleBuyerValue'] as num?)?.toDouble(),
      saleBuyerType: json['saleBuyerType'] ?? 'PERCENTAGE',
      saleSellerValue: (json['saleSellerValue'] as num?)?.toDouble(),
      saleSellerType: json['saleSellerType'] ?? 'PERCENTAGE',
      saleAgentValue: (json['saleAgentValue'] as num?)?.toDouble(),
      saleAgentType: json['saleAgentType'] ?? 'PERCENTAGE',
      paymentTiming: json['paymentTiming'],
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rentBuyerValue': rentBuyerValue,
      'rentBuyerType': rentBuyerType,
      'rentSellerValue': rentSellerValue,
      'rentSellerType': rentSellerType,
      'rentAgentValue': rentAgentValue,
      'rentAgentType': rentAgentType,
      'saleBuyerValue': saleBuyerValue,
      'saleBuyerType': saleBuyerType,
      'saleSellerValue': saleSellerValue,
      'saleSellerType': saleSellerType,
      'saleAgentValue': saleAgentValue,
      'saleAgentType': saleAgentType,
      'paymentTiming': paymentTiming,
      'paymentMethod': paymentMethod,
    };
  }
}
