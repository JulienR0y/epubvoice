import { View, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import ChapterList from '@/components/ChapterList';
import { useEpubParser } from '@/hooks/useEpubParser';

export default function LibraryScreen() {
  const router = useRouter();
  const { chapters } = useEpubParser();

  function handleChapterSelect(index: number) {
    router.push({ pathname: '/reader', params: { chapterIndex: index } });
  }

  return (
    <View style={styles.container}>
      <ChapterList chapters={chapters} onSelect={handleChapterSelect} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a1a',
  },
});
