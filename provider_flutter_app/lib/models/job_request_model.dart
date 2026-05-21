class JobRequestModel {
  final String id;
  final String title;
  final String description;
  final String address;
  final double estimatedEarnings;
  final DateTime scheduledTime;
  final String status; // 'pending', 'accepted', 'in_progress', 'completed'

  JobRequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.estimatedEarnings,
    required this.scheduledTime,
    required this.status,
  });
}
