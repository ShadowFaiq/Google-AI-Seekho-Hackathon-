import '../models/provider_model.dart';
import '../models/job_request_model.dart';

class MockData {
  static final ProviderModel currentProvider = ProviderModel(
    id: 'p1',
    name: 'Ahmed Khan',
    email: 'ahmed.khan@example.com',
    phone: '+92 300 1234567',
    profileImageUrl: 'https://via.placeholder.com/150',
    rating: 4.8,
    totalJobs: 142,
    totalEarnings: 45000.0,
    status: 'Online',
  );

  static final List<JobRequestModel> jobRequests = [
    JobRequestModel(
      id: 'j1',
      title: 'AC Repair & Maintenance',
      description: 'Split AC is not cooling properly. Needs service.',
      address: 'House 42, Street 5, DHA Phase 4, Lahore',
      estimatedEarnings: 1500.0,
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      status: 'pending',
    ),
    JobRequestModel(
      id: 'j2',
      title: 'Plumbing - Leak Fix',
      description: 'Bathroom sink pipe is leaking.',
      address: 'Apartment 12B, Gulberg III, Lahore',
      estimatedEarnings: 800.0,
      scheduledTime: DateTime.now().add(const Duration(days: 1)),
      status: 'accepted',
    ),
    JobRequestModel(
      id: 'j3',
      title: 'Electrical Wiring',
      description: 'Install new ceiling fan in living room.',
      address: 'Plot 7, Model Town, Lahore',
      estimatedEarnings: 1200.0,
      scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'in_progress',
    ),
  ];
}
