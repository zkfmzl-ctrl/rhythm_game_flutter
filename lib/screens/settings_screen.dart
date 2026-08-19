part of '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.musicVolume,
    required this.effectVolume,
    required this.vibration,
    required this.laneSpeed,
    required this.muted,
    required this.onMusic,
    required this.onEffect,
    required this.onVibration,
    required this.onLaneSpeed,
    required this.onMuteToggle,
    super.key,
  });

  final double musicVolume;
  final double effectVolume;
  final bool vibration;
  final double laneSpeed;
  final bool muted;
  final ValueChanged<double> onMusic;
  final ValueChanged<double> onEffect;
  final ValueChanged<bool> onVibration;
  final ValueChanged<double> onLaneSpeed;
  final VoidCallback onMuteToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const PageTitle('설정', subtitle: '게임 환경 설정'),
        _SettingRow(
          label: '전체 음소거 (배경음악 + 효과음)',
          trailing: PaperToggle(value: muted, onChanged: (_) => onMuteToggle()),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: muted ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: muted,
            child: Column(
              children: [
                SettingSlider(
                    label: '음악 볼륨', value: musicVolume, onChanged: onMusic),
                const SizedBox(height: 10),
                SettingSlider(
                  label: '효과음 볼륨',
                  value: effectVolume,
                  onChanged: onEffect,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          label: '진동',
          trailing: PaperToggle(value: vibration, onChanged: onVibration),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          label: '노트 속도',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onLaneSpeed(math.max(0.5, laneSpeed - 0.1)),
                icon: const Icon(Icons.remove),
              ),
              Text(
                '${laneSpeed.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              IconButton(
                onPressed: () => onLaneSpeed(math.min(2.0, laneSpeed + 0.1)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _SettingRow(label: '판정 보조'),
        const SizedBox(height: 10),
        const _SettingRow(label: '그래픽/배경 효과'),
        const SizedBox(height: 10),
        const _SettingRow(label: '데이터 초기화'),
      ],
    );
  }
}

class SettingSlider extends StatelessWidget {
  const SettingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: PaperPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 94,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${value.round()}%',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: PaperPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
