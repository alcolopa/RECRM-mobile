class Property {
  final String id;
  final String organizationId;
  final String title;
  final String? description;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? price;
  final String currency;
  final int? bedrooms;
  final double? bathrooms;
  final double? area; // typically in sqm
  final double? sizeSqm;
  final String status;
  final String listingType;
  final String type;
  final List<String> images;
  final List<String> features;
  final int? yearBuilt;
  final String? condition;
  final bool furnished;
  final String? assignedUserId;

  Property({
    required this.id,
    required this.organizationId,
    required this.title,
    this.description,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.price,
    this.currency = 'USD',
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.sizeSqm,
    required this.status,
    required this.listingType,
    required this.type,
    this.images = const [],
    this.features = const [],
    this.yearBuilt,
    this.condition,
    this.furnished = false,
    this.assignedUserId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['propertyImages'] != null) {
      parsedImages = (json['propertyImages'] as List)
          .map((img) => img['url'] as String)
          .toList();
    }

    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      parsedFeatures = List<String>.from(json['features']);
    }

    return Property(
      id: json['id'] ?? '',
      organizationId: json['organizationId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      currency: json['currency'] ?? 'USD',
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'] != null
          ? double.tryParse(json['bathrooms'].toString())
          : null,
      area: json['area'] != null
          ? double.tryParse(json['area'].toString())
          : null,
      sizeSqm: json['sizeSqm'] != null
          ? double.tryParse(json['sizeSqm'].toString())
          : null,
      status: json['status'] ?? 'AVAILABLE',
      listingType: json['listingType'] ?? 'SALE',
      type: json['type'] ?? 'HOUSE',
      images: parsedImages,
      features: parsedFeatures,
      yearBuilt: json['yearBuilt'],
      condition: json['condition'],
      furnished: json['furnished'] ?? false,
      assignedUserId: json['assignedUserId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'price': price,
      'currency': currency,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'sizeSqm': sizeSqm,
      'status': status,
      'listingType': listingType,
      'type': type,
      'yearBuilt': yearBuilt,
      'condition': condition,
      'furnished': furnished,
      'assignedUserId': assignedUserId,
    };
  }
}
