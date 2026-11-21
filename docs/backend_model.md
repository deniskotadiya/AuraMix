# Draft backend model (implement with secure server rules/functions)

## Collections

- `users/{uid}`: displayName, avatarUrl, bio, createdAt, accountState (public profile fields only).
- `users/{uid}/favorites/{controlId}`: savedAt.
- `users/{uid}/createdControls/{controlId}`: owner reference or metadata summary.
- `users/{uid}/recent/{entryId}`: controlId, playedAt.
- `controls/{controlId}`: title, description, creatorId, visibility (`private`/`public`), category, tags, coverUrl, soundLayers[], premiumAccess, likeCount, dislikeCount, saveCount, playCount, score, moderationStatus, createdAt, updatedAt.
- `controls/{controlId}/reactions/{uid}`: type (`like`/`dislike`), updatedAt. Use backend transaction; clients must not write aggregate counts.
- `controls/{controlId}/songSuggestions/{suggestionId}`: title, artist, canonicalUrl, platform, submitterId, score counts, moderationStatus, createdAt.
- `controls/{controlId}/songSuggestions/{suggestionId}/votes/{uid}`: vote type and timestamp.
- `reports/{reportId}`: reporterId, targetType, targetId, reason, status, createdAt. Access restricted.
- `soundCatalog/{soundId}`: title, category, assetUrl, licenseRecordId, premium, enabled, metadata.

## Visibility model

Public reads should only return controls with `visibility=public` AND `moderationStatus=approved`. Private controls must be owner-only. Avoid queries that fetch private records and filter them on the client. Security rules should deny all reads/writes not explicitly allowed. A public-to-private update should remove the mix from public discovery immediately.


## Functions / transactions

- `reactToControl(controlId, reaction)` — authenticated; one reaction per user, idempotent update; update counters in transaction/server.
- `voteSongSuggestion(controlId, suggestionId, vote)` — authenticated and one vote per user.
- `incrementControlPlay(controlId)` — rate-limited; do not trust arbitrary client counters.
- `publishControl(controlId)` — validate ownership, metadata, sound catalog IDs, visibility and moderation.
- `reportContent(...)` — validate report and rate limit.
- `recomputeRanking()` — server-side score; avoid exposing raw user engagement data unnecessarily.
- Account deletion — delete/anonimize user profile, private mixes, user votes/reactions, recommendations, uploaded content according to documented policy; public creator content should have a clearly documented ownership/retention policy.

## Index / search

Firestore filter+sort combinations will require indexes. Add them based on exact Discover queries. Firestore is not full-text search; for scalable text search across title/description/creator/tags, add Algolia, Typesense, Meilisearch or another dedicated search service if needed.

## Anti-abuse / moderation

Require authentication for publishing, reactions and suggestions; apply rate limits; validate music links against supported schemes/domains; prevent arbitrary executable content; moderate cover uploads; offer report/block; maintain moderator actions/audit; do not accept client-authored aggregate score fields.
