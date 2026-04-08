class Lead {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String status;
  final String? source;
  final String organizationId;
  final String? assignedUserId;
  final String? budget;
  final DateTime? convertedAt;
  final String? convertedContactId;
  final String? notes;
  final String? preferredLocation;
  final String? propertyType;
  final String intent;
  final List<String> amenities;
  final String? urgencyLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.status,
    this.source,
    required this.organizationId,
    this.assignedUserId,
    this.budget,
    this.convertedAt,
    this.convertedContactId,
    this.notes,
    this.preferredLocation,
    this.propertyType,
    this.intent = 'SALE',
    this.amenities = const [],
    this.urgencyLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      source: json['source'],
      organizationId: json['organizationId'],
      assignedUserId: json['assignedUserId'],
      budget: json['budget']?.toString(),
      convertedAt: json['convertedAt'] != null
          ? DateTime.parse(json['convertedAt'])
          : null,
      convertedContactId: json['convertedContactId'],
      notes: json['notes'],
      preferredLocation: json['preferredLocation'],
      propertyType: json['propertyType'],
      intent: json['intent'] ?? 'SALE',
      amenities: List<String>.from(json['amenities'] ?? []),
      urgencyLevel: json['urgencyLevel'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'source': source,
      'budget': budget,
      'notes': notes,
      'preferredLocation': preferredLocation,
      'propertyType': propertyType,
      'intent': intent,
      'amenities': amenities,
      'urgencyLevel': urgencyLevel,
    };
  }

  String get fullName => '$firstName $lastName';
}
