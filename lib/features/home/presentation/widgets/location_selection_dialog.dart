import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/filter_location_options.dart';

Future<String?> showLocationSelectionDialog({
  required BuildContext context,
  required String selectedLocation,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text('Select Location', style: AppTypography.homeMatchTitle18),
        contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 360),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: FilterLocationOptions.values.length,
            itemBuilder: (context, index) {
              final location = FilterLocationOptions.values[index];
              final isSelected = location == selectedLocation;

              return ListTile(
                onTap: () => Navigator.of(dialogContext).pop(location),
                title: Text(
                  location,
                  style: AppTypography.homeMeta14.copyWith(
                    color: AppColors.heading,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.primary,
                      )
                    : null,
              );
            },
          ),
        ),
      );
    },
  );
}
