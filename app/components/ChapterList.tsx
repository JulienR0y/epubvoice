import { FlatList, TouchableOpacity, Text, StyleSheet, View } from 'react-native';

export interface Chapter {
  title: string;
  paragraphs: string[];
}

interface ChapterListProps {
  chapters: Chapter[];
  onSelect: (index: number) => void;
}

export default function ChapterList({ chapters, onSelect }: ChapterListProps) {
  return (
    <FlatList
      data={chapters}
      keyExtractor={(_, i) => String(i)}
      contentContainerStyle={styles.list}
      renderItem={({ item, index }) => (
        <TouchableOpacity style={styles.item} onPress={() => onSelect(index)}>
          <Text style={styles.number}>{index + 1}</Text>
          <Text style={styles.title} numberOfLines={2}>
            {item.title}
          </Text>
        </TouchableOpacity>
      )}
      ItemSeparatorComponent={() => <View style={styles.separator} />}
    />
  );
}

const styles = StyleSheet.create({
  list: {
    padding: 16,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    gap: 16,
  },
  number: {
    fontSize: 14,
    color: '#666666',
    width: 28,
    textAlign: 'right',
  },
  title: {
    flex: 1,
    fontSize: 16,
    color: '#ffffff',
  },
  separator: {
    height: 1,
    backgroundColor: '#2a2a2a',
  },
});
