part of '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.musicVolume,
    required this.effectVolume,
    required this.vibration,
    required this.laneSpeed,
    required this.onMusic,
    required this.onEffect,
    required this.onVibration,
    required this.onLaneSpeed,
    super.key,
  });
  final double musicVolume;
  final double effectVolume;
  final bool vibration;
  final double laneSpeed;
  final ValueChanged<double> onMusic;
  final ValueChanged<double> onEffect;
  final ValueChanged<bool> onVibration;
  final ValueChanged<double> onLaneSpeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('설정', subtitle: '게임 환경 설정'),
        SettingSlider(label: '음악 볼륨', value: musicVolume, onChanged: onMusic),
        SettingSlider(
          label: '효과음 볼륨',
          value: effectVolume,
          onChanged: onEffect,
        ),
        PaperPanel(
          child: SwitchListTile(
            title: const Text(
              '진동',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            value: vibration,
            onChanged: onVibration,
          ),
        ),
        const SizedBox(height: 12),
        PaperPanel(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '노트 속도',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
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
        const SizedBox(height: 12),
        const PaperPanel(
          child: Text('판정 보조', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        const PaperPanel(
          child:
              Text('그래픽/배경 효과', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        const PaperPanel(
          child: Text('데이터 초기화', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PaperPanel(
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: Text(
                label,
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
            Text('${value.round()}%'),
          ],
        ),
      ),
    );
  }
}
