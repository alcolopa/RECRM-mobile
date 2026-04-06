class Contact {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String? secondaryPhone;
  final String type; // ContactType enum
  final String? leadSource;
  final String? assignedAgentId;
  final String status; // ContactStatus enum
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastContactedAt;
  final String organizationId;

  Contact({
    required this.id,
    required this.organizationId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    this.secondaryPhone,
    required this.type,
    this.leadSource,
    this.assignedAgentId,
    required this.status,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastContactedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      organizationId: json['organizationId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      secondaryPhone: json['secondaryPhone'],
      type: json['type'],
      leadSource: json['leadSource'],
      assignedAgentId: json['assignedAgentId'],
      status: json['status'],
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastContactedAt: json['lastContactedAt'] != null 
          ? DateTime.parse(json['lastContactedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'type': type,
      'leadSource': leadSource,
      'assignedAgentId': assignedAgentId,
      'status': status,
      'notes': notes,
      'tags': tags,
    };
  }

  String get fullName => '$firstName $lastName';
}
