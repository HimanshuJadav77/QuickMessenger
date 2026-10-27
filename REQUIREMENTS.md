# Requirements: Quick Messenger UI/UX Audit & Quality Enhancement

## 1. Objectives
- Perform a complete, repository-wide UI/UX audit of Quick Messenger (Flutter).
- Standardize design system, typography, colors, spacing, and component geometry.
- Enforce strict avatar and list consistency across all screens (chat lists, contact lists, search, blocked users, following, group members, profiles).
- Optimize local media caching and reuse: prevent re-downloading files already present locally, deduplicate concurrent downloads, validate files safely, and preserve remote fallback.
- Fix visual bugs, contrast issues (e.g. sender file bubble in dark mode), and layout overflows.
- Preserve all existing messaging logic, Firebase sync, socket connections, traffic-signal indicators, and Google Drive upload logic.

## 2. Non-Negotiable Boundaries (Protected Functionality)
- **Chat & Messaging Logic**:
  - Message-sending, message-receiving, real-time socket & Firebase sync must not be altered.
  - Message IDs, conversation IDs, participant mapping, ordering, timestamps, delivery indicators, read receipts, and unread counts must remain identical.
  - Traffic-signal status indicators (🔴 Red: Not Send, 🟡 Yellow: Send, 🟢 Green: Seen) must retain their exact logic and meaning.
- **Backend & Database**:
  - Firestore collection paths, documents, queries, and security rules must not be modified.
  - Riverpod state management architecture must be preserved.
- **Drive Uploads**:
  - `DriveService` upload requests, authentication, and file storage logic must remain intact.
