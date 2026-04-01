import { useState, useRef, useCallback, useEffect } from 'react';
import * as Speech from 'expo-speech';

type Speed = 0.75 | 1 | 1.25 | 1.5;

export function useTTS(paragraphs: string[], chapterIndex: number) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentParagraph, setCurrentParagraph] = useState(0);
  const [speed, setSpeed] = useState<Speed>(1);

  // Keep a ref so the speech callback always sees the current index
  const paragraphRef = useRef(currentParagraph);
  paragraphRef.current = currentParagraph;

  // Stop speech whenever the chapter changes
  useEffect(() => {
    Speech.stop();
    setIsPlaying(false);
    setCurrentParagraph(0);
  }, [chapterIndex]);

  const speakCurrent = useCallback(
    (index: number) => {
      const text = paragraphs[index];
      if (!text) {
        setIsPlaying(false);
        return;
      }

      Speech.speak(text, {
        rate: speed,
        onDone: () => {
          const next = paragraphRef.current + 1;
          if (next < paragraphs.length) {
            setCurrentParagraph(next);
            speakCurrent(next);
          } else {
            setIsPlaying(false);
          }
        },
        onStopped: () => setIsPlaying(false),
        onError: () => setIsPlaying(false),
      });
    },
    [paragraphs, speed],
  );

  const play = useCallback(() => {
    setIsPlaying(true);
    speakCurrent(currentParagraph);
  }, [currentParagraph, speakCurrent]);

  const pause = useCallback(() => {
    Speech.stop();
    setIsPlaying(false);
  }, []);

  const skipForward = useCallback(() => {
    Speech.stop();
    const next = Math.min(currentParagraph + 1, paragraphs.length - 1);
    setCurrentParagraph(next);
    if (isPlaying) speakCurrent(next);
  }, [currentParagraph, isPlaying, paragraphs.length, speakCurrent]);

  const skipBackward = useCallback(() => {
    Speech.stop();
    const prev = Math.max(currentParagraph - 1, 0);
    setCurrentParagraph(prev);
    if (isPlaying) speakCurrent(prev);
  }, [currentParagraph, isPlaying, speakCurrent]);

  return {
    isPlaying,
    speed,
    currentParagraph,
    play,
    pause,
    skipForward,
    skipBackward,
    setSpeed: (s: Speed) => {
      setSpeed(s);
      // If playing, restart current paragraph at new speed
      if (isPlaying) {
        Speech.stop();
        speakCurrent(paragraphRef.current);
      }
    },
  };
}
