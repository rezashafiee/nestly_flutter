# Offline-First Implementation Notes

This document explains what was used, where it was used, and how the
offline-first flow works in Nestly.

## Development Tools Used

| Tool | Used for |
| --- | --- |
| `rg` / `sed` | Inspecting repository structure, UI widgets, controllers, models, and repositories before changing code. |
| `apply_patch` | Creating and editing source files in a controlled, reviewable way. |
| `flutter pub get` | Restoring the local Flutter dependency cache so formatter, analyzer, and tests could run. |
| `dart format` | Formatting changed Dart files after implementation. |
| `flutter analyze` | Static verification that the Flutter/Dart code has no analyzer issues. |
| `flutter test` | Running the controller, widget, and offline-first repository tests. |
| `http/testing` `MockClient` | Testing offline/online repository behavior without a real backend. |

## Code Tools And Components

| Component | Purpose |
| --- | --- |
| `OfflineJsonStore` | Small JSON persistence API used by repositories. It reads and writes maps/lists without exposing platform details. |
| `FileOfflineStoreBackend` | Native desktop/mobile storage backend. It writes JSON files under the user's local Nestly cache directory, falling back to temp storage. |
| `BrowserOfflineStoreBackend` | Web storage backend. It writes JSON to browser `localStorage`. |
| `MemoryOfflineStoreBackend` | In-memory backend for tests and unsupported fallback paths. |
| Model `toJson()` methods | Allow `Listing`, `Conversation`, and `ChatMessage` to be cached and restored safely. |
| Repository sync flags | `isUsingOfflineData`, `hasPendingWrites`, and `syncMessage` tell controllers/UI when data is saved locally or waiting to sync. |
| `InfoBanner` | User-facing banner for saved-data and pending-sync states. |

## Offline-First Process

### App Startup

1. `NestlyApp` creates one shared `OfflineJsonStore`.
2. Auth, listings, and chat repositories receive that store.
3. `AuthController.restoreSession()` tries to restore the last cached profile.
4. Once the user reaches marketplace or chat, controllers ask repositories to restore cached data before trying the network.

### Listings

1. `MarketplaceController.refresh()` first calls `ListingsRepository.restoreListings()`.
2. If cached listings exist, the UI can render them immediately.
3. `fetchListings()` then tries to sync pending local listings and fetch fresh backend listings.
4. If the network fails, the repository keeps cached data. If there is no cache yet, it falls back to bundled starter listings.
5. Offline publishes create a local `local-listing-*` item, save it to cache, and queue the publish request.
6. The next successful refresh posts queued listings, replaces local IDs with backend IDs, updates cache, and clears the pending flag.

### Chat

1. `ChatController.refresh()` asks `ChatRepository.restoreConversations()` for saved chats first.
2. `fetchConversations()` then tries to sync pending chat starts and messages before fetching fresh conversations.
3. Starting a chat offline creates a `local-chat-*` conversation and queues a `start` operation.
4. Sending a message offline appends the message locally and queues a `message` operation.
5. When refresh succeeds online, queued chat starts are posted first. Local chat IDs are mapped to server IDs, then queued messages are sent to the mapped server conversation.
6. Cached conversations are rewritten after successful sync.

### Auth

1. Successful online sign-in stores the returned `UserProfile`.
2. If email or Google sign-in cannot reach the backend, auth falls back to a cached profile when possible.
3. If no profile exists for email sign-in, the app creates a local profile from the email so the offline app can continue.
4. Sign-out clears the cached profile.

### Photos

1. `PhotoRepository.captureForCategory()` still asks the backend for a category photo asset.
2. If the photo service is unavailable, it falls back to bundled category assets.
3. This keeps the sell flow usable offline.

### UI Feedback

1. Controllers expose sync state from repositories.
2. Marketplace and chat show `InfoBanner` when the app is rendering saved data or has pending sync work.
3. Sell success copy changes based on sync state: online listings are described as live; offline listings are described as saved locally.

## Icon And Button Audit

The UI uses Material button/icon defaults for primary actions:

- `IconButton.filled` and `IconButton.filledTonal` are used for compact icon-only commands such as refresh, offline simulation, chat, and send.
- `FilledButton.icon` is used for primary text actions such as continue, publish, sign in, take photo, and chat.
- `OutlinedButton.icon` is used for secondary actions such as back, close, choose photo, retry-like secondary actions, and sign out.
- Small status icons use explicit compact sizes (`14` in pills, `20` in banners).
- Loading indicators inside buttons use fixed `18 x 18` sizing so button height does not jump.
- Shared listing photo icons now scale to their container and category badges are hidden on compact thumbnails, preventing oversized icons or clipped badges in chat list tiles.

## Verification

The current verification process is:

1. Run `dart format lib test`.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Review key UI surfaces after icon/button changes: marketplace header/actions, listing cards, chat list/detail, sell flow actions, auth buttons, account metrics, and navigation shell.
