class ProviderModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final double rating;
  final int totalJobs;
  final double totalEarnings;
  final String status;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.rating,
    required this.totalJobs,
    required this.totalEarnings,
    required this.status,
  });
}
