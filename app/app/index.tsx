import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import ImportButton from '@/components/ImportButton';
import { useEpubParser } from '@/hooks/useEpubParser';

export default function HomeScreen() {
  const router = useRouter();
  const { loadEpub } = useEpubParser();

  async function handleImport(fileUri: string) {
    await loadEpub(fileUri);
    router.push('/library');
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>EpubVoice</Text>
      <Text style={styles.subtitle}>Import an epub to get started</Text>
      <ImportButton onImport={handleImport} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
    backgroundColor: '#1a1a1a',
    padding: 24,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#ffffff',
  },
  subtitle: {
    fontSize: 16,
    color: '#888888',
  },
});
