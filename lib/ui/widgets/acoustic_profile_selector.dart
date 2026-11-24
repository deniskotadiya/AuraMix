import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../core/dps_engine.dart';
import '../../models/acoustic_profile.dart';

class AcousticProfileSelector extends StatelessWidget {
  final bool compact;
  final VoidCallback? onProfileChanged;

  const AcousticProfileSelector({
    super.key,
    this.compact = false,
    this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DPSEngine.instance,
      builder: (context, _) {
        final activeType = DPSEngine.instance.activeDeviceProfileType;
        final activeProfile = DPSEngine.instance.activeDeviceProfile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  activeProfile.icon,
                  size: 15,
                  color: AppTheme.neonCyan,
                ),
                const SizedBox(width: 6),
                const Text(
                  'ACOUSTIC OUTPUT TARGET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonCyan.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.carNeonGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activeProfile.shortLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Profile Toggle Buttons
            SizedBox(
              height: compact ? 38 : 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: AcousticProfile.defaultProfiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final profile = AcousticProfile.defaultProfiles[index];
                  final isSelected = profile.type == activeType;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.mediumImpact();
                        DPSEngine.instance.setAcousticProfile(profile.type);
                        onProfileChanged?.call();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.neonCyan.withAlpha(45)
                            : const Color(0xFF14172B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.neonCyan : Colors.white12,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.neonCyan.withAlpha(60),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.icon,
                            size: compact ? 15 : 18,
                            color: isSelected ? AppTheme.neonCyan : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.title,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (!compact) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activeProfile.description,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
