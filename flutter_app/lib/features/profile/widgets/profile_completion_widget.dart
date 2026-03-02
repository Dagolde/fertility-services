import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final User user;
  final VoidCallback? onCompleteProfile;

  const ProfileCompletionWidget({
    super.key,
    required this.user,
    this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    final completionPercentage = _calculateCompletionPercentage();
    final missingFields = _getMissingFields();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${completionPercentage.round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPercentage >= 80
                    ? Colors.green
                    : completionPercentage >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            if (missingFields.isNotEmpty) ...[
              Text(
                'Complete your profile by adding:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              ...missingFields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          field,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCompleteProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('Complete Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Profile Complete!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your profile has been completed successfully. It is now pending admin verification.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateCompletionPercentage() {
    int completedFields = 0;
    int totalFields = 0;

    // Basic information (required)
    totalFields += 4; // firstName, lastName, email, userType
    completedFields += 4; // These are always present

    // Profile information (optional but important)
    totalFields += 1; // phone
    if (user.phone != null && user.phone!.isNotEmpty) completedFields += 1;

    totalFields += 1; // dateOfBirth
    if (user.dateOfBirth != null) completedFields += 1;

    totalFields += 1; // gender
    if (user.gender != null && user.gender!.isNotEmpty) completedFields += 1;

    totalFields += 1; // profilePicture
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) completedFields += 1;

    totalFields += 1; // bio
    if (user.bio != null && user.bio!.isNotEmpty) completedFields += 1;

    // Location information
    totalFields += 1; // address
    if (user.address != null && user.address!.isNotEmpty) completedFields += 1;

    totalFields += 1; // city
    if (user.city != null && user.city!.isNotEmpty) completedFields += 1;

    totalFields += 1; // state
    if (user.state != null && user.state!.isNotEmpty) completedFields += 1;

    totalFields += 1; // country
    if (user.country != null && user.country!.isNotEmpty) completedFields += 1;

    totalFields += 1; // postalCode
    if (user.postalCode != null && user.postalCode!.isNotEmpty) completedFields += 1;

    return (completedFields / totalFields) * 100;
  }

  List<String> _getMissingFields() {
    final missingFields = <String>[];

    if (user.phone == null || user.phone!.isEmpty) {
      missingFields.add('Phone number');
    }

    if (user.dateOfBirth == null) {
      missingFields.add('Date of birth');
    }

    if (user.gender == null || user.gender!.isEmpty) {
      missingFields.add('Gender');
    }

    if (user.profilePicture == null || user.profilePicture!.isEmpty) {
      missingFields.add('Profile picture');
    }

    if (user.bio == null || user.bio!.isEmpty) {
      missingFields.add('Bio/About me');
    }

    if (user.address == null || user.address!.isEmpty) {
      missingFields.add('Address');
    }

    if (user.city == null || user.city!.isEmpty) {
      missingFields.add('City');
    }

    if (user.state == null || user.state!.isEmpty) {
      missingFields.add('State/Province');
    }

    if (user.country == null || user.country!.isEmpty) {
      missingFields.add('Country');
    }

    return missingFields;
  }
}
