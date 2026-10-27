# Project State: Quick Messenger UI/UX Standardization, Bug Fixes & Performance Optimization

## 1. Executive Summary
A comprehensive, repository-wide UI/UX standardization, bug remediation, and performance optimization has been executed across QuickMessenger. All hand-rolled avatars, broken Google Drive image links, hardcoded theme overrides, filter pill inconsistencies, N+1 Firestore queries in follower/following lists, dangling privacy tags, and switch contrast anomalies have been corrected while strictly preserving all underlying business logic, real-time messaging, database structures, and Google Drive upload systems.

---

## 2. Completed Milestones

### Phase 1: Core Design System & Tokens
- **Adaptive Contrast Tokens (`AppColors`)**:
  - `onPrimary(bool isDark)`: High-contrast foreground for primary filled surfaces.
  - `bubbleMe(bool isDark)` / `bubbleMeText(bool isDark)`: Inverted message bubble styling preventing white-on-white text in dark mode.
  - `bubbleOther(bool isDark)` / `bubbleOtherText(bool isDark)`: High-legibility received bubble tokens.
  - `surfaceContainer(bool isDark)`: Standardized container fill replacing scattered ad-hoc hex codes.
- **Cupertino State Widgets**:
  - `EmptyStateWidget`: Replaced Material `ElevatedButton` with native `CupertinoButton` and `AppTypography`.
  - `ErrorStateWidget`: Replaced Material `OutlinedButton` with native `CupertinoButton`.
- **Navigation Safety (`AppSnackbar`)**:
  - Guarded snackbar timer dismissal with `if (entry.mounted)` to eliminate unmounted overlay dispose crashes.

### Phase 2: Media Caching & Message Bubble Contrast
- **`MediaCacheService` Optimization**:
  - Deterministic cache keys (`getCacheKey`) using Drive file IDs or URL hashes.
  - In-flight request deduplication (`_inFlightDownloads`) preventing duplicate concurrent fetches.
  - Atomic `.tmp` staging with HTML error validation to prevent corrupted/throttled files from polluting cache.
  - Fast local cache lookup (`getCachedFilePath`, `isFileValid`).
- **`MessageBubble` Robustness**:
  - Auto-checks local disk before attempting network or Drive fetch.
  - Fixed sender file bubble (`_FileBubble`) text contrast bug in dark mode using `AppColors.bubbleMeText(widget.isDark)`.
  - Wired `onMediaDownloaded` in `group_chat_screen.dart` to persist local media paths via `updateMessageLocalPath`.

### Phase 3: Avatar Harmonization & Semantic Dimensions
- **Semantic Sizing Constants (`AppAvatarSize`)**:
  - `listTile = 26.0` (52px diameter)
  - `header = 18.0` (36px diameter)
  - `compact = 20.0` (40px diameter)
  - `chip = 22.0` (44px diameter)
  - `settingsHero = 30.0` (60px diameter)
  - `profileHero = 48.0` (96px diameter)
  - `callHero = 55.0` (110px diameter)
- **Screens Refactored with `UserAvatar`**:
  - `user_search_screen.dart`: Standardized list tile with `leadingSize: 52`, `seed: uid`, and `AppAvatarSize.listTile`.
  - `followers_following_screen.dart`: Replaced raw container with `UserAvatar(seed: otherId)`.
  - `blocked_users_screen.dart`: Replaced raw container with `UserAvatar`.
  - `user_profile_screen.dart`: Proportionate `UserAvatar(radius: AppAvatarSize.profileHero, seed: userid)`.
  - `following_chats_screen.dart`: Unified list tile to `leadingSize: 52` and `AppAvatarSize.listTile`.
  - `calls_tab_screen.dart`: Unified recent call tiles to `leadingSize: 52` and `AppAvatarSize.listTile`.
  - `message_search_screen.dart`: Replaced icon box with `UserAvatar` for group or direct chat icons.
  - `create_group_screen.dart`: Standardized selection tray with `AppAvatarSize.chip` and member list with `AppAvatarSize.listTile`.
  - `group_profile_screen.dart`: Updated group hero avatar to `AppAvatarSize.profileHero` and member rows to `AppAvatarSize.listTile`.
  - `notification_screen.dart`: Standardized follow request and follower list tiles with `leadingSize: 52` and `AppAvatarSize.listTile`.

### Phase 4: Filter Chip Standardization (`AppFilterChip`)
- Created `AppFilterChip` widget based on the reference design from CallsTabScreen (`calls_tab_screen.dart`).
- Standardized:
  - 32-34px minimum height touch target with `BorderRadius.circular(20)`
  - Active: `accent.withValues(alpha: isDark ? 0.25 : 0.16)` + border `accent.withValues(alpha: 0.6)` + bold text
  - Inactive: `isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)`
  - Integrated into `calls_tab_screen.dart`, `following_chats_screen.dart`, and `chat_list_screen.dart`.
  - Removed deprecated `_Pill` implementation.

### Phase 5: Local-First Avatar Caching Strategy
- Implemented `AvatarCacheService`:
  - Instant synchronous memory cache lookup (`getCachedPathSync`).
  - Persistent local disk caching in `$appDoc/QuickMessenger/Avatars/`.
  - In-flight request deduplication (`_inFlightDownloads`) preventing duplicate concurrent avatar downloads.
  - Atomic `.tmp` file download staging with image validation.
  - Dedicated user cache invalidation (`invalidateUser`) wired to `profile_screen.dart` avatar updates.
- Integrated `_AvatarImage` within `UserAvatar`:
  - Synchronous cache hit displays `Image.file` immediately without network latency or flicker.
  - Missing avatars fetch in the background and cache locally for all subsequent screens.
  - Graceful fallback to deterministic gradient letter avatar.

### Phase 6: Chats Screen & Top Actions Standardization
- Refactored `chat_list_screen.dart`:
  - Replaced raw `GestureDetector` with properly themed `CupertinoButton(minimumSize: const Size(38, 38))` and `AppColors.onPrimary(isDark)`.
  - Cleaned up top header hierarchy and action layout.
  - Integrated `AppFilterChip` with live unread badge count.

### Phase 7: Profile Screen & Public Badge Cleanup
- **`profile_screen.dart`**:
  - Standardized hero avatar from 110px container to proportionate `UserAvatar(radius: AppAvatarSize.profileHero)` with camera action overlay.
  - Wired avatar cache invalidation upon saving a new photo.
- **`user_profile_screen.dart`**:
  - Repositioned the awkward dangling "Public/Private" text into a clean badge pill located directly below the avatar with lock/globe icon.
  - Standardized chat action button with `CupertinoButton(minimumSize: const Size(46, 46))` and `AppColors.onPrimary(isDark)`.
  - Passed `seed: widget.userid` to `UserAvatar` for stable caching.

### Phase 8: Followers & Following N+1 Optimization
- Rebuilt `followers_following_screen.dart`:
  - Eliminated N+1 Firestore queries via `_CachedUserTile`:
    1. Checks in-memory cache first.
    2. Checks SQLite `LocalDatabaseHelper.instance.getUserProfile` next.
    3. Fetches from Firestore only on cache miss with in-flight deduplication.
    4. Caches fetched profiles into SQLite for permanent instant lookup.
  - Added direct Chat button on each list tile opening `ChatScreen` with pre-filled participant data.
  - Handled long names with `TextOverflow.ellipsis`.

### Phase 9: Activity Screen Bug Fixes (`notification_screen.dart`)
- Fixed critical bug where accepted follow requests were not cleared from the `requests` subcollection, causing ghost requests to persist.
- Updated `_confirmAccept` to clear both `request: false` and `requested: false`.
- Passed stable `seed: doc.id` to `UserAvatar`.
- Added `TextOverflow.ellipsis` to titles and subtitles to prevent layout shifts.
- Themed Accept button with `AppColors.onPrimary(isDark)`.

### Phase 10: High-Contrast Switches (`AppSwitch`)
- Created `AppSwitch` in `lib/core/widgets/app_switch.dart`.
- Enforces high contrast:
  - `activeTrackColor: accent`
  - `inactiveTrackColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)`
  - `thumbColor: CupertinoColors.white`
- Replaced `CupertinoSwitch` in `settings_screen.dart` for Dark Mode and Private Account.

### Phase 11: Message Ordering on First Open & Timestamp Normalization
- Root Cause Remediated: When syncing messages from the socket on fresh installs (`onSyncComplete`), messages were inserted into SQLite and appended sequentially without deterministic sorting. Server batches in reverse chronological order resulted in inverted list presentation on first open. In group chats, `getGroupMessages` queried `ASC` without reversal, breaking pagination.
- Added `MessageModel.sortAndDeduplicate(Iterable<MessageModel>)`:
  - Deterministically deduplicates by `messageId`.
  - Preserves advanced statuses (`read > seen > delivered > sent > pending > uploading`).
  - Merges local file paths and remote drive IDs.
  - Sorts chronologically ascending (`client_created_at` ASC, tiebroken by `messageId`).
- Added robust multi-format timestamp parser to `MessageModel.fromMap` handling `client_created_at`, `clientCreatedAt`, `created_at`, `createdAt`, `timestamp`, Firestore `Timestamp`, and epoch millis/seconds.
- Fixed `LocalDatabaseHelper.getGroupMessages` to query `DESC` with `rows.reversed.toList()` matching `getMessagesForConversation`.
- Enforced `MessageModel.sortAndDeduplicate` across `chat_repository.dart`, `ChatMessagesNotifier`, and `GroupMessagesNotifier`.
- Added `findChildIndexCallback` in `chat_screen.dart` and `group_chat_screen.dart` `ListView.builder` for O(1) item element recycling and zero visible jumping.

### Phase 12: Standardized Single-Row App Screen Headers
- Created `lib/core/widgets/app_screen_header.dart`:
  - `AppScreenHeader`: Standardized 32pt bold title, vertically centered on identical baseline across all main tabs, left-aligned with graceful truncation, and right-aligned actions with 38x38 touch targets.
  - `AppHeaderIconButton`: Standardized circular action button (38x38) with theme-aware styling, high-contrast icon, and tactile feedback.
- Applied across all primary navigation screens:
  - `chat_list_screen.dart`: Title "Chats" + Plus button.
  - `calls_tab_screen.dart`: Title "Calls" + New Call button (eliminated awkward two-row layout).
  - `following_chats_screen.dart`: Title "Communities" + Search + Plus buttons (eliminated awkward two-row layout).
  - `notification_screen.dart`: Standardized "Activity" header.
  - `settings_screen.dart`: Title "You" + Edit Profile pencil button (eliminated awkward two-row layout).

### Phase 13: Activity Screen Avatar & Navigation Fix
- Fixed avatar URL extraction in `notification_screen.dart` (`userData['userimageurl'] ?? userData['imageurl'] ?? userData['image_url'] ?? userData['photoURL'] ?? ''`).
- Derived `UserAvatar` gradient fallback strictly from `seed!.trim()` when provided, guaranteeing consistent gradient colors for the same user across all screens.
- Updated `_openProfile` navigation in `notification_screen.dart` to take `targetUserId` (`update.id` or `doc.id`), fixing bug where missing `userData["userid"]` caused `null` user profile navigation.
- Fixed `AppColors.onPrimary` in dark mode to return high-contrast white `Color(0xFFFFFFFF)` instead of black.

### Phase 14: Exact Schema Alignment with Quick_Messenger_Server
- Inspected the authoritative backend server code in `D:\My Projects\Quick_Messenger_Server`:
  - `src/services/chat.service.js` (Firestore message document schema, idempotency checks, conversation metadata).
  - `src/socket/chat.events.js` (`send_message`, `message_sent`, `message_received`, `message_delivered`, `read_receipt`, `message_edited`, `message_deleted`, `message_reaction_updated`).
  - `src/socket/offline-sync.js` (`sync_messages`, `sync_complete`, `syncPendingUnseenMessages`).
  - `src/socket/group.events.js` & `src/services/group.service.js` (`create_group`, `send_group_message`, `group_message_received`).
  - `src/socket/call.events.js` (`call_offer`, `call_answer`, `call_rejected`, `call_ended`, Agora tokens).
- Replaced loose, multi-assumption fallback chains (e.g. searching for imaginary keys like `content`, `timestamp`, `serverCreatedAt`) with exact-match dedicated factories:
  - `MessageModel.fromDb(Map)`: 1-to-1 exact mapping to SQLite table `messages` columns (`message_id`, `conversation_id`, `client_created_at`, `reactions_json`, etc.).
  - `MessageModel.fromServer(Map)`: 1-to-1 exact mapping to `Quick_Messenger_Server` payloads (`messageId`, `conversationId`, `clientCreatedAt`, `reactions`, etc.).
  - `ConversationModel.fromDb` & `ConversationModel.fromServer`: Exact SQLite columns (`id`, `participant_id`, `last_message`, etc.) vs Server keys (`conversationId`, `participantId`, `lastMessage`, etc.).
  - `GroupModel.fromDb` & `GroupModel.fromServer`: Exact SQLite columns vs Server keys.
  - `GroupMemberModel.fromDb` & `GroupMemberModel.fromServer`: Exact SQLite columns vs Server keys.
  - `CallModel`: Direct 1-to-1 match with `call.events.js` payload.
- Unified `fromMap` factory methods to dispatch to `fromDb` or `fromServer` based on schema presence, preserving complete backwards compatibility with existing callers.

### Phase 15: Full-Application 60 FPS Performance Engineering & Smoothness Optimization
- **High-Performance Local-First Profile Cache (`UserProfileCacheService`)**:
  - Eliminates N+1 Firestore queries across list tiles, activity, and search screens.
  - 4-tier retrieval: 1) Synchronous memory cache (0ms hit), 2) Local SQLite hit (`LocalDatabaseHelper.getUserProfile`), 3) In-flight request deduplication (`_inFlightFetches`), 4) Background Firestore fetch with local persistence.
- **Synchronous Media Path Memory Cache (`MediaCacheService.getCachedPathSync`)**:
  - Added `_memoryPathCache` and `getCachedPathSync` to eliminate file system stats and async delays when scrolling past cached images.
- **Raster Thread & Image Decoding Optimizations (`UserAvatar` & `MessageBubble`)**:
  - Bound `cacheWidth` and `cacheHeight` (clamped 48-512px on avatars, 220-800px on bubbles) on `Image.file` and `Image.network`, eliminating decoding of unconstrained multi-megapixel camera images during list scrolling.
  - Wrapped `UserAvatar` and `ConversationTile` in `RepaintBoundary` to isolate GPU rasterization.
  - Short-circuited `TweenAnimationBuilder` when `animateEntrance` is false, eliminating animation controller overhead during historical scrolling in `chat_screen.dart` and `group_chat_screen.dart`.
- **Elimination of N+1 Live Firestore Stream Storms (`notification_screen.dart`)**:
  - Replaced inner `StreamBuilder` instances (which opened dozens of live Firestore document listeners on every follower/request) with a dedicated `_ActivityUserTile` consuming `UserProfileCacheService`.
  - Memoized `_requestsStream` and `_followersStream` so searching/filtering does not recreate streams or trigger full-screen loading spinners.
- **Stream Memoization in `calls_tab_screen.dart` & `following_chats_screen.dart`**:
  - Memoized `_callsStream` and `_followingStream` to prevent stream re-creation, state resets, and UI flicker when switching filter chips or typing queries.
  - Replaced inline `FutureBuilder(future: Users.doc(id).get())` inside `_FollowedUserTile.build()` with local-first cached `_FollowedUserTileState`.
- **Scroll & Sliver Element Identity (`findChildIndexCallback` & `RepaintBoundary`)**:
  - Placed `ValueKey(msg.messageId)` on outer `RepaintBoundary` in `chat_screen.dart` and `group_chat_screen.dart`, enabling Flutter's `findChildIndexCallback` to locate elements correctly.
  - Implemented `findChildIndexCallback` on `SliverChildBuilderDelegate` in `chat_list_screen.dart` and `following_chats_screen.dart`.
  - Made `DateFormat` instances `static final` in `conversation_tile.dart` (`_timeFormat`, `_weekdayFormat`, `_dateFormat`), eliminating repetitive regex/locale initialization and GC allocation churn during rapid scrolling.

### Phase 16: Complete Application UI/UX Refactor, Cross-Theme Contrast Remediation & Technical Copy Cleanup
- **Cross-Theme Brightness & Contrast Architecture**:
  - Root cause diagnosed and eliminated: `main.dart` configured root `CupertinoApp` with `CupertinoThemeData`, but did not inject a matching Material `Theme` ancestor in `builder`. Consequently, widgets querying `Theme.of(context).brightness` fell back to `ThemeData.fallback()` (`Brightness.light`), causing dark OLED mode to compute `isDark = false` and render black icons/text on dark backgrounds in `ChatAppBar`, `call_screen.dart`, `glass_input.dart`, `liquid_glass_container.dart`, and `glass_loading_overlay.dart`.
  - Added centralized `AppColors.isDarkMode(BuildContext context)` helper that simultaneously interrogates `CupertinoTheme` and Material `Theme`.
  - Wrapped `CupertinoApp.builder` in `Theme(data: isDark ? AppTheme.darkOledTheme(accent) : AppTheme.lightTheme(accent))` so Material and Cupertino subtrees are 100% unified in both Light and Dark modes.
  - Refactored all theme brightness queries across `ChatAppBar`, `call_screen.dart`, `liquid_glass_container.dart`, `glass_loading_overlay.dart`, `glass_tile.dart`, `glass_input.dart`, `emoji_reaction_picker_sheet.dart`, `liquid_glass_app_bar.dart`, and `liquid_glass_navigation_bar.dart` to use `AppColors.isDarkMode(context)`.
  - Explicitly bound `color: AppColors.textPrimary(isDark)` on username header in `ChatAppBar` to prevent font style override collision.
- **Elimination of Technical / Internal Jargon & Unverified Claims**:
  - `about_screen.dart`: Replaced internal architecture text ("Local persistence: SQLite, per-user keys", "Real-time transport: Socket.IO + FCM", "Authentication: Firebase secure token", "Architecture: Local-first, Riverpod state") with professional user-facing copy ("Data & Storage: Saved locally on your device", "Messaging: Fast real-time chat & media delivery", "Security: Protected account authentication", "Voice & Video: High-definition peer calls").
  - `call_screen.dart`: Replaced unverified promotional claim `'End-to-end Encrypted'` with honest, user-oriented `'Secure Call'`.
  - `lg_context_menu.dart`: Replaced `"🔒 Messages are end-to-end encrypted"` with `"🔒 Secure Conversation"`.
  - `profile_screen.dart`: Replaced internal technical exception ("Failed to upload image. Please check your Firebase Storage Rules or Google Drive permissions.") with friendly, actionable user copy ("Failed to upload photo. Please check your network connection and try again.").
  - `auth_gate_screen.dart`: Removed internal statements about Google Drive media synchronization, replacing them with authentic messaging app descriptions and standard Terms/Privacy agreement notices.
  - `message_bubble.dart`: Replaced internal drive text (`'Uploading to Drive... • $sizeStr'`) with user-facing status (`'Uploading... • $sizeStr'`).
  - `chat_list_screen.dart`: Purged commented-out legacy encrypted caption footer block.
  - `sender_message_card.dart`: Updated theme logic with `AppColors.isDarkMode(context)`.
### Phase 15: AppBar Trailing Action Icon Theming, ListTile Spacing Standardization, Aspect-Ratio Image Rendering & "Delete for Everyone" Legibility
- **Fix AppBar Trailing Action Icon Colors (Issue 1)**:
  - Root Cause Diagnosed: In `AppHeaderIconButton` (`lib/core/widgets/app_screen_header.dart`), when `isPrimary: true`, the foreground was hardcoded to `Colors.white`. In Dark OLED theme, the primary accent is `0xFFFFFFFF` (White), causing a white icon on a white circle background (100% invisible). In addition, un-themed trailing actions in `LiquidGlassAppBar`, `profile_screen.dart`, `user_profile_screen.dart`, and `group_chat_screen.dart` lacked explicit semantic foreground tokens.
  - Fix Implemented: Replaced hardcoded `Colors.white` with `AppColors.onPrimary(isDark, bg)` in `AppHeaderIconButton`. Wrapped actions in `LiquidGlassAppBar` with `IconTheme(data: IconThemeData(color: AppColors.textPrimary(isDark)))`. Configured `actionsIconTheme` and `iconTheme` on `AppBarTheme` in both `lightTheme` and `darkOledTheme`. Added explicit `AppColors.textPrimary(isDark)` and `textSecondary(isDark)` to navigation trailing actions across profile and group chat screens.
- **Fix Widget Padding, Spacing, and Inconsistent ListTile Layout (Issue 2)**:
  - Root Cause Diagnosed: List tiles in `following_chats_screen.dart` used horizontal padding of 14px, `ConversationTile` used 16px, while `calls_tab_screen.dart`, `user_search_screen.dart`, `notification_screen.dart`, `followers_following_screen.dart`, and others omitted `padding:`, falling back to Cupertino's unaligned 20px default. Avatars jumped between 14px, 16px, and 20px horizontally across screens.
  - Fix Implemented: Established reusable design system tokens in `AppSpacing`: `listTilePadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)`, `listTileLeadingSize = 52.0`, and `listTileLeadingToTitle = 12.0`. Standardized all `CupertinoListTile` instances across `calls_tab_screen.dart`, `following_chats_screen.dart`, `user_search_screen.dart`, `notification_screen.dart`, `followers_following_screen.dart`, `group_profile_screen.dart`, `create_group_screen.dart`, `blocked_users_screen.dart`, and `message_search_screen.dart`.
- **Fix Image Rendering After Loading & Prevent Aspect-Ratio Distortion (Issue 3)**:
  - Root Cause Diagnosed: `UserAvatar` and `_ImageBubble` passed both `cacheWidth: cacheDim` and `cacheHeight: cacheDim` into Flutter's `ResizeImage`. Providing both forces Flutter to rasterize images non-proportionally into square bitmaps, causing stretching/squishing of rectangular photos. Additionally, network images omitted `frameBuilder`, displaying blank empty boxes during download that caused jarring layout shifts when decoded.
  - Fix Implemented: Removed `cacheHeight` and retained only `cacheWidth: cacheDim` across `UserAvatar` (`_AvatarImageState`) and `message_bubble.dart` (`_ImageBubbleState`), allowing Flutter to downscale while preserving native aspect ratios. Added `frameBuilder` to `Image.network` to smoothly display fallback/placeholder widgets until decoded, eliminating sudden layout shifts.
- **Fix "Delete for Everyone" Message Theme Colors (Issue 4)**:
  - Root Cause Diagnosed: In `message_bubble.dart`, when `isMe == true` and `isDeleted == true`, text color was resolved using `AppColors.background(isDark).withValues(alpha: 0.7)` inside a bubble styled as `AppColors.receiverBubble(isDark).withValues(alpha: 0.4)`. In light mode, `background(false)` is white, rendering white italic text on light gray (illegible). In dark mode, `background(true)` is black, rendering translucent black text on dark slate.
  - Fix Implemented: Standardized deleted message bubble background to `isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8E8ED)` and border to `Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))`. Deleted message text and timestamp now use `AppColors.textMuted(isDark)` with `FontStyle.italic`. Suppressed `MessageStatusIcon` (sent/delivered/read ticks) on deleted messages, added a subtle `CupertinoIcons.slash_circle` indicator, and removed `Copy`/`Forward` options from the action sheet for deleted messages.
- **Regression & Verification Tests Added**:
  - Added test groups in `test/ui_and_cache_test.dart`:
    1. `AppHeaderIconButton` dark mode contrast (white bg -> black icon; luminance < 0.2) and light mode contrast (black bg -> white icon; luminance > 0.8).
    2. `AppSpacing` metrics verification (`listTilePadding`, `listTileLeadingSize`, `listTileLeadingToTitle`).
    3. Deleted message text readability and contrast verification in both Light and Dark themes.

---

## 3. Verification & Quality Gates
- **Static Analysis**: `cmd.exe /c "flutter analyze"` executed with **0 issues found** (No errors, no warnings, no hints across all files).
- **Test Suite**: `cmd.exe /c "flutter test"` executed with **57/57 tests passing** (100% pass rate).
- **Protected Boundaries Preserved**:
  - Message sending/receiving logic unchanged.
  - Traffic-signal delivery indicators (`message_status_icon.dart` 🔴/🟡/🟢) unchanged.
  - Google Drive upload engine (`DriveService`) unchanged.
  - Firestore database schemas, collection paths, and relationships unchanged.
