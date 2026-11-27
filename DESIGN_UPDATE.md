# AETHERA UI refresh

## What changed

- Reworked the farmer home screen with a photographic field hero, stronger visual hierarchy, richer icon treatment, and subtle entrance motion on tool cards.
- Replaced the assistant orb panel with a clear voice-assistant entry point and a photographic assistant header.
- Rebuilt the Tunisian Derja voice screen around a press-and-hold microphone interaction.
- Added a responsive animated waveform driven by the microphone sound-level callback while listening, plus a separate speaking state.
- Kept typed questions, the existing speech recognition service, and text-to-speech response flow.
- Corrected the assistant's crop-diagnosis action to open the diagnosis screen rather than the voice screen.

## Remote image sources

The two photographic hero images are loaded from Unsplash's image CDN through the already-installed `cached_network_image` package. They require an internet connection at runtime and have solid-color fallbacks if loading fails.

- Farmer dashboard: `https://images.unsplash.com/photo-1470252649378-9c29740c9fa8`
- Assistant header: `https://images.unsplash.com/photo-1500382017468-9049fed747ef`

For an offline or production build, download appropriately licensed image files into `app/assets/images/` and replace the remote URLs with local `Image.asset` widgets.

## Voice interaction behavior

- Press and hold the microphone to start speech recognition.
- Release the microphone to stop listening and submit the recognized text.
- The waveform responds to the speech plugin's sound-level events while recording.
- The existing typed-question and text-to-speech paths remain available.

Speech recognition availability and locale support depend on the browser/device speech service. The current response content remains the existing local rule-based Derja guidance; this UI update does not connect a new AI model or backend voice endpoint.

## Dependencies

No new Flutter package was added. The implementation uses the existing `cached_network_image`, `speech_to_text`, and `flutter_tts` dependencies, along with Flutter's built-in animation widgets and `AnimationController`.
