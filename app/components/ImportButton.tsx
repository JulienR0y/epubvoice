import { TouchableOpacity, Text, StyleSheet, ActivityIndicator } from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';
import { useState } from 'react';

interface ImportButtonProps {
  onImport: (fileUri: string) => Promise<void>;
}

export default function ImportButton({ onImport }: ImportButtonProps) {
  const [loading, setLoading] = useState(false);

  async function handlePress() {
    const result = await DocumentPicker.getDocumentAsync({
      type: 'application/epub+zip',
      copyToCacheDirectory: false,
    });

    if (result.canceled) return;

    setLoading(true);
    try {
      const source = result.assets[0].uri;
      const dest = FileSystem.documentDirectory + 'current.epub';
      await FileSystem.copyAsync({ from: source, to: dest });
      await onImport(dest);
    } finally {
      setLoading(false);
    }
  }

  return (
    <TouchableOpacity style={styles.button} onPress={handlePress} disabled={loading}>
      {loading ? (
        <ActivityIndicator color="#1a1a1a" />
      ) : (
        <Text style={styles.label}>Import Epub</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: '#ffffff',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 8,
    minWidth: 160,
    alignItems: 'center',
  },
  label: {
    color: '#1a1a1a',
    fontSize: 16,
    fontWeight: '600',
  },
});
