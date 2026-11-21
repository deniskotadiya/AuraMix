# AuraMix updated starter feature matrix

## Working locally in the prototype
- Required profile gate with local demo profile persistence; Firebase email/password mode when Firebase is configured and enabled.
- Neon gradient dark UI, page transition animation, sound-layer cards, and bottom navigation.
- Ten bundled synthesized ambience loops: Rain, Ocean, Forest, Fireplace, Wind, Birds, White Noise, Brown Noise, Pink Noise, Cafe.
- Independent just_audio players per ambience layer, looping, toggles, individual volume.
- Local audio picker and foreground player for one selected audio file. Audio stays local and is not uploaded.
- Optional GPS permission/current-location check triggered by the user, with location feature description.
- Demo Discover data, filters/sorting, reactions, saves, custom control creation and private/public selection, song recommendation form, Premium/restore UI placeholders.
- App icon source and launcher icon generation configuration.

## Not production connected
- Firebase community persistence and server-side visibility enforcement/security rules.
- Rewarded ads and ad consent.
- RevenueCat/store billing, receipt verification, subscription state, restore purchases.
- Actual public profiles, moderation/reporting, song recommendation persistence/upvotes.
- Location-triggered geofences/automatic sound triggers.
- Social login providers.
- Background playback service/lock-screen media controls for local imported songs.
- Production audio assets: bundled WAV files are synthetic sound textures, not field recordings.

## Release blockers
Implement backend, billing/ad services, production authentication, moderation/privacy flows, background playback if required, proper legal/licensing review, and device testing before publishing.
