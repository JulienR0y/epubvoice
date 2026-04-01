import { useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = 'epubvoice:progress';

export interface Progress {
  chapterIndex: number;
  paragraphIndex: number;
}

export async function loadProgress(): Promise<Progress | null> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as Progress) : null;
  } catch {
    return null;
  }
}

/** Saves progress whenever chapterIndex or paragraphIndex changes. */
export function useProgress(chapterIndex: number, paragraphIndex: number) {
  useEffect(() => {
    AsyncStorage.setItem(KEY, JSON.stringify({ chapterIndex, paragraphIndex })).catch(
      () => {},
    );
  }, [chapterIndex, paragraphIndex]);
}
