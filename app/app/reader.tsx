import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import PlayerControls from '@/components/PlayerControls';
import { useEpubParser } from '@/hooks/useEpubParser';
import { useTTS } from '@/hooks/useTTS';
import { useProgress } from '@/hooks/useProgress';

export default function ReaderScreen() {
  const { chapterIndex } = useLocalSearchParams<{ chapterIndex: string }>();
  const index = parseInt(chapterIndex ?? '0', 10);

  const { chapters } = useEpubParser();
  const chapter = chapters[index];

  const {
    isPlaying,
    speed,
    currentParagraph,
    play,
    pause,
    skipForward,
    skipBackward,
    setSpeed,
  } = useTTS(chapter?.paragraphs ?? [], index);

  useProgress(index, currentParagraph);

  return (
    <View style={styles.container}>
      <ScrollView style={styles.textArea} contentContainerStyle={styles.textContent}>
        <Text style={styles.chapterTitle}>{chapter?.title ?? ''}</Text>
        {(chapter?.paragraphs ?? []).map((p, i) => (
          <Text
            key={i}
            style={[styles.paragraph, i === currentParagraph && styles.activeParagraph]}
          >
            {p}
          </Text>
        ))}
      </ScrollView>
      <PlayerControls
        isPlaying={isPlaying}
        speed={speed}
        onPlay={play}
        onPause={pause}
        onSkipForward={skipForward}
        onSkipBackward={skipBackward}
        onSpeedChange={setSpeed}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a1a',
  },
  textArea: {
    flex: 1,
    padding: 20,
  },
  textContent: {
    paddingBottom: 40,
  },
  chapterTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 20,
  },
  paragraph: {
    fontSize: 17,
    lineHeight: 28,
    color: '#cccccc',
    marginBottom: 16,
  },
  activeParagraph: {
    color: '#ffffff',
    backgroundColor: '#2a2a2a',
    borderRadius: 4,
    padding: 4,
  },
});
