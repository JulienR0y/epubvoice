import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';

const SPEEDS = [0.75, 1, 1.25, 1.5] as const;
type Speed = (typeof SPEEDS)[number];

interface PlayerControlsProps {
  isPlaying: boolean;
  speed: Speed;
  onPlay: () => void;
  onPause: () => void;
  onSkipForward: () => void;
  onSkipBackward: () => void;
  onSpeedChange: (speed: Speed) => void;
}

export default function PlayerControls({
  isPlaying,
  speed,
  onPlay,
  onPause,
  onSkipForward,
  onSkipBackward,
  onSpeedChange,
}: PlayerControlsProps) {
  function cycleSpeed() {
    const next = SPEEDS[(SPEEDS.indexOf(speed) + 1) % SPEEDS.length];
    onSpeedChange(next);
  }

  return (
    <View style={styles.container}>
      <View style={styles.row}>
        <TouchableOpacity style={styles.iconBtn} onPress={onSkipBackward}>
          <Text style={styles.icon}>⏮</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.playBtn} onPress={isPlaying ? onPause : onPlay}>
          <Text style={styles.playIcon}>{isPlaying ? '⏸' : '▶'}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.iconBtn} onPress={onSkipForward}>
          <Text style={styles.icon}>⏭</Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.speedBtn} onPress={cycleSpeed}>
        <Text style={styles.speedLabel}>{speed}×</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#111111',
    borderTopWidth: 1,
    borderTopColor: '#2a2a2a',
    paddingVertical: 20,
    paddingHorizontal: 32,
    alignItems: 'center',
    gap: 16,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 32,
  },
  iconBtn: {
    padding: 8,
  },
  icon: {
    fontSize: 28,
    color: '#ffffff',
  },
  playBtn: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  playIcon: {
    fontSize: 28,
    color: '#1a1a1a',
  },
  speedBtn: {
    paddingVertical: 6,
    paddingHorizontal: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#444444',
  },
  speedLabel: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
});
