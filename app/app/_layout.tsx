import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: '#1a1a1a' },
          headerTintColor: '#ffffff',
          contentStyle: { backgroundColor: '#1a1a1a' },
        }}
      >
        <Stack.Screen name="index" options={{ title: 'EpubVoice' }} />
        <Stack.Screen name="library" options={{ title: 'Chapters' }} />
        <Stack.Screen name="reader" options={{ title: 'Reader' }} />
      </Stack>
    </>
  );
}
