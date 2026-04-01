import { useState, useCallback } from 'react';
import ePub from 'epubjs';
import * as FileSystem from 'expo-file-system';
import { Chapter } from '@/components/ChapterList';
import { stripHtml, splitIntoParagraphs } from '@/utils/epubUtils';

// epubjs works in a browser-like env — React Native needs the file read as base64
// and passed as an ArrayBuffer-compatible blob.

export function useEpubParser() {
  const [chapters, setChapters] = useState<Chapter[]>([]);

  const loadEpub = useCallback(async (fileUri: string) => {
    const base64 = await FileSystem.readAsStringAsync(fileUri, {
      encoding: FileSystem.EncodingType.Base64,
    });

    // Decode base64 to binary string then to Uint8Array for epubjs
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }

    const book = ePub(bytes.buffer);
    await book.ready;

    const spine = book.spine as any;
    const items = spine.items as any[];

    const parsed: Chapter[] = [];

    for (const item of items) {
      const section = book.spine.get(item.href);
      if (!section) continue;

      const doc = await section.load(book.load.bind(book));
      const html = (doc as Document).documentElement?.innerHTML ?? '';
      const text = stripHtml(html);
      const paragraphs = splitIntoParagraphs(text);

      if (paragraphs.length === 0) continue;

      // Try to extract a title from the first short paragraph or fall back to href
      const title =
        paragraphs[0].length < 80 ? paragraphs[0] : item.href.replace(/[/_-]/g, ' ');

      parsed.push({ title, paragraphs });
    }

    setChapters(parsed);
  }, []);

  return { chapters, loadEpub };
}
