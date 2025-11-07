class Startup {
  final String id;
  final String name;
  final String sector;
  final String geography;
  final String fundingStage;
  final String logo;
  final String website;
  final String description;

  Startup({
    required this.id,
    required this.name,
    required this.sector,
    required this.geography,
    required this.fundingStage,
    required this.logo,
    required this.website,
    required this.description,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['startup_id'],
      name: json['name'],
      sector: json['sector'],
      geography: json['geography'],
      fundingStage: json['funding_stage'],
      logo: json['logo'],
      website: json['website'],
      description: json['description'],
    );
  }
}
