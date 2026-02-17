---
name: mobile-backend
description: Design and build production-grade backend systems specifically optimized for mobile applications. Use this skill when the user asks to build APIs for mobile apps, mobile BFF (Backend for Frontend) layers, push notification services, real-time sync backends, offline-first server architectures, or any server-side logic that serves mobile clients (examples include mobile auth flows, media upload APIs, device management endpoints, app versioning APIs, or when architecting backend infrastructure for React Native, Flutter, iOS, or Android apps). Generates secure, mobile-aware, battery-friendly backend code that avoids desktop-web assumptions.
---

This skill guides creation of robust, production-grade backend systems specifically designed to serve mobile clients. Mobile backends have unique requirements — unreliable networks, battery constraints, limited bandwidth, platform-specific push systems, and offline-first expectations — that generic web backends fail to address. Implement real working code with exceptional attention to mobile-specific concerns.

The user provides mobile backend requirements: APIs, services, sync engines, or infrastructure to build. They may include context about the mobile framework (Flutter, React Native, SwiftUI), expected user base, offline needs, or deployment target.

## Architectural Thinking

Before coding, understand the mobile context and commit to the right backend strategy:
- **Client Profile**: What mobile frameworks will consume this API? (Flutter, React Native, SwiftUI, Jetpack Compose). How many platforms?
- **Connectivity**: Will users have reliable internet? Design for spotty 3G, airplane mode, underground transit. Offline-first or online-first with graceful degradation?
- **Data Flow**: Is data mostly read-heavy (feed apps), write-heavy (logging/tracking), bidirectional (chat/collaboration), or burst-heavy (media uploads)?
- **Platform Services**: Which platform-specific services are needed? (APNs, FCM, deep linking, in-app purchases, app clips/instant apps)
- **Lifecycle**: Mobile apps have complex lifecycles — background/foreground, force-quit, OS-level throttling. How does the backend handle interrupted operations?

**CRITICAL**: Mobile backends are NOT web backends with a different client. They require fundamentally different design decisions around payload sizes, sync strategies, auth token management, and connection handling. A backend that works great for web browsers may be hostile to mobile clients.

Then implement working code that is:
- Production-grade, secure, and functional
- Optimized for mobile constraints (bandwidth, battery, intermittent connectivity)
- Resilient to unstable network conditions and interrupted requests
- Designed with proper sync, caching, and conflict resolution strategies

## Mobile-Specific API Design

### Request & Response Optimization
- **Compact payloads**: Use field selection / sparse fieldsets. Let clients request only the fields they need (`?fields=id,name,avatar`). Mobile screens show less data than web — don't send everything.
- **Pagination**: Use cursor-based pagination for infinite scroll feeds. Include `hasMore` and `nextCursor` in responses. Never use offset-based pagination for user-facing feeds — it breaks with real-time inserts.
- **Compression**: Always support gzip/brotli compression. For large responses, the bandwidth savings are dramatic on cellular networks.
- **Image variants**: Serve device-appropriate image sizes. Accept `width` and `dpr` (device pixel ratio) parameters. Return optimized formats (WebP, AVIF). Never send a 4K image to a phone that will display it at 375px.
- **Batch endpoints**: Provide batch/bulk APIs for operations the mobile app needs to do in sequence. One round-trip is always better than ten on a 200ms-latency cellular connection.
- **Delta sync**: For data that changes incrementally, support delta/diff endpoints that return only what changed since a given timestamp or version. `GET /api/v1/feed?since=2024-01-15T10:30:00Z`

### BFF (Backend for Frontend) Pattern
When mobile and web need different data shapes, use a BFF layer:
```
Mobile Client → Mobile BFF API → Shared Backend Services → Database
Web Client   → Web BFF API   → Shared Backend Services → Database
```
The BFF aggregates, transforms, and optimizes responses specifically for mobile screen layouts and navigation flows. Keep BFFs thin — they orchestrate, not implement business logic.

## Authentication & Security for Mobile

- **Token management**: Use short-lived access tokens (15-30 min) with long-lived refresh tokens (30-90 days). Mobile users shouldn't re-login every session. Implement silent token refresh in API middleware.
- **Refresh token rotation**: Issue a new refresh token with every refresh. Invalidate the old one. Detect token reuse as a potential breach — revoke the entire family.
- **Device registration**: Track devices per user. Allow users to see and revoke active devices. Use device fingerprinting (device model, OS version, app version) for security signals.
- **Biometric auth bridge**: Support backend-driven biometric authentication. Store biometric-encrypted credentials on-device, validate challenge-response server-side.
- **OAuth2 + PKCE**: Always use PKCE (Proof Key for Code Exchange) for mobile OAuth flows. Mobile apps cannot securely store client secrets. Never use the implicit grant.
- **Certificate pinning support**: Provide certificate/public key hashes for clients to pin. Document rotation schedules. Implement pin backup keys.
- **Rate limiting by device**: Rate limit per device ID in addition to per user/IP. Prevent compromised devices from affecting the account.

## Push Notifications

Design a unified push system that handles platform differences:

```
Notification Service
├── APNs Provider (iOS)          → Apple Push Notification Service
├── FCM Provider (Android/Web)   → Firebase Cloud Messaging
├── Fallback Provider             → SMS / Email for critical alerts
└── Notification Store            → In-app notification history
```

- **Registration**: Accept device tokens per platform. Handle token refresh (tokens change). Support multiple devices per user.
- **Delivery**: Use priority levels — `high` for time-sensitive (messages, alerts), `normal` for deferrable (marketing, updates). Respect platform-specific payload limits (APNs: 4KB, FCM: 4KB).
- **Silent pushes**: Use data-only pushes to trigger background sync without user-visible notifications. Essential for keeping app data fresh.
- **Notification preferences**: Let users control channels (push, email, SMS) and categories (messages, marketing, system). Store preferences server-side and respect them.
- **Analytics**: Track delivery, open, and dismiss rates. Use these to optimize timing and content.

## Offline-First & Data Sync

### Sync Strategies
```
What sync model fits the app?
├── Read-mostly (news, catalog)
│   └── Pull-based sync with ETags / Last-Modified headers
│       Cache-Control for staleness, background refresh
├── Collaborative (docs, boards, chat)
│   └── Operational Transform or CRDTs
│       Real-time via WebSockets, conflict-free merges
├── Form/task-based (surveys, inspections)
│   └── Outbox pattern with retry queue
│       Queue writes locally, drain to server when online
└── Bidirectional (notes, contacts, calendar)
    └── Timestamp-based sync with conflict detection
        Server-wins, client-wins, or manual merge
```

- **Conflict resolution**: Choose a strategy and document it. Server-wins is simplest. Last-write-wins works for most cases. Field-level merge for complex documents. Always let the user know when conflicts are resolved.
- **Outbox pattern**: Queue offline writes in a local outbox. Process them FIFO when connectivity returns. Implement idempotency keys so retries are safe.
- **Sync status**: Expose sync state per record (`synced`, `pending`, `failed`, `conflict`). Let the mobile client show sync indicators.
- **Version vectors**: For multi-device sync, use version vectors or Lamport timestamps to track causality across devices.

## Real-Time Communication

- **WebSocket management**: Implement heartbeat/ping-pong to detect dead connections. Auto-reconnect with exponential backoff. Handle mobile app backgrounding (OS kills WebSocket connections).
- **Fallback strategy**: WebSocket → SSE → Long polling → Regular polling. Degrade gracefully based on client capabilities and network conditions.
- **Presence**: Track online/offline/away status. Use heartbeats (every 30s) with a grace period (90s) before marking offline. Broadcast presence changes efficiently.
- **Message delivery guarantees**: Implement at-least-once delivery with client-side deduplication. Use message IDs and sequence numbers. Support message acknowledgment.
- **Connection recovery**: On reconnect, sync missed messages using a cursor/sequence number. Never assume the client has received everything — always allow catch-up.

## Media & File Handling

- **Upload**: Use presigned URLs for direct-to-storage uploads (S3, GCS, Azure Blob). Never proxy large files through your API server. Support chunked/resumable uploads for large files (use tus protocol or similar). Accept upload progress callbacks.
- **Processing pipeline**: Process media asynchronously after upload. Generate thumbnails, transcode video, extract metadata in background workers. Notify the client when processing completes (via push or polling).
- **Download**: Serve optimized variants. Support range requests for resume-capable downloads. Use CDN for static assets. Set proper cache headers — images rarely change.
- **Size limits**: Enforce per-file and per-user storage quotas. Return clear errors with limits included (`max_size_bytes`, `remaining_quota`).

## Project Structure

Organize mobile backend projects with mobile-specific concerns clearly separated:

```
project-root/
├── src/
│   ├── config/              # Environment, database, push, storage config
│   ├── routes/
│   │   ├── v1/              # API v1 routes (versioned from day one)
│   │   └── v2/              # API v2 routes (when needed)
│   ├── controllers/         # Thin request handlers
│   ├── services/
│   │   ├── auth/            # Token management, OAuth, device registration
│   │   ├── push/            # Notification dispatch (APNs, FCM)
│   │   ├── sync/            # Offline sync, conflict resolution
│   │   ├── media/           # Upload, processing, CDN management
│   │   └── [domain]/        # Business logic services
│   ├── models/              # Data models, schemas
│   ├── middleware/
│   │   ├── auth.ts          # Token validation, refresh
│   │   ├── device.ts        # Device identification, version checks
│   │   ├── rateLimit.ts     # Per-device and per-user rate limiting
│   │   └── apiVersion.ts    # Version negotiation, deprecation warnings
│   ├── jobs/                # Background workers (media processing, push, sync)
│   ├── validators/          # Input validation
│   ├── utils/               # Shared helpers
│   └── types/               # Type definitions
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── migrations/
├── scripts/
│   ├── send-push.ts         # Manual push notification testing
│   └── seed-devices.ts      # Seed test device data
└── docs/
    ├── api/                 # API documentation (OpenAPI/Swagger)
    ├── push-setup.md        # Platform push configuration guide
    └── sync-protocol.md     # Sync protocol documentation
```

## App Versioning & Backward Compatibility

- **API versioning**: Version from day one (`/api/v1/`). Use header-based versioning (`Accept: application/vnd.app.v2+json`) as an alternative. Never break existing versions.
- **Minimum app version**: Enforce minimum client versions. Return `426 Upgrade Required` with a link to the app store when clients are too old. Use a `X-Min-App-Version` header.
- **Feature flags**: Use server-driven feature flags to control rollout. Ship features in the binary but activate them server-side. This enables gradual rollout and instant kill-switches.
- **Deprecation**: Warn clients of deprecated endpoints via response headers (`Deprecation: true`, `Sunset: 2024-06-01`). Log usage of deprecated endpoints to track migration progress.
- **Config endpoint**: Expose a `/config` or `/bootstrap` endpoint that returns dynamic configuration — feature flags, minimum versions, maintenance mode, API base URLs. Mobile apps should check this on startup.

## Anti-Patterns to Avoid

NEVER build mobile backends that:
- Return full database records when the client only needs 3 fields
- Send 2000px images to a device that displays them at 100px
- Require 10 API calls to render a single screen (no aggregation/BFF)
- Use session cookies instead of token-based auth for mobile
- Ignore offline scenarios — "just show an error" is not a strategy
- Send push notifications without user preference checks
- Use offset pagination for infinite scroll feeds
- Force app updates by breaking the API without version negotiation
- Store push tokens without associating them to users/devices
- Return HTML error pages to API clients
- Assume mobile clients have the same processing power as servers
- Skip idempotency on write endpoints (mobile clients retry a LOT)
- Use large, uncompressed JSON payloads over cellular networks
- Ignore device timezone when scheduling notifications
- Treat all mobile platforms identically (APNs ≠ FCM)

## Framework & Tooling Quick Reference

| Component            | Options                                                          |
| -------------------- | ---------------------------------------------------------------- |
| **API Framework**    | Express, Fastify, NestJS, FastAPI, Django REST, Go Gin, Spring   |
| **Real-time**        | Socket.IO, ws, Ably, Pusher, Supabase Realtime, Firebase RTDB   |
| **Push (iOS)**       | node-apn, APNs HTTP/2, Expo Push, OneSignal                     |
| **Push (Android)**   | firebase-admin, FCM HTTP v1, Expo Push, OneSignal                |
| **Storage**          | AWS S3, Google Cloud Storage, Cloudflare R2, Supabase Storage    |
| **Media Processing** | Sharp, FFmpeg, Cloudinary, Imgix, AWS MediaConvert               |
| **Auth**             | Passport.js, Auth0, Firebase Auth, Supabase Auth, Clerk          |
| **Queue/Jobs**       | BullMQ, Celery, Sidekiq, AWS SQS, Google Cloud Tasks             |
| **Database**         | PostgreSQL, MongoDB, Supabase, Firebase Firestore, PlanetScale   |
| **Cache**            | Redis, Memcached, Cloudflare KV                                  |
| **Monitoring**       | Sentry, DataDog, New Relic, Grafana + Prometheus                 |

## Decision Framework

```
What kind of mobile backend does this app need?
├── Simple data API (profiles, settings, content)
│   └── REST API, single DB, token auth, basic caching
├── Social / feed-based (posts, comments, likes)
│   └── REST + cursor pagination, Redis caching, push notifications, CDN for media
├── Real-time / messaging (chat, collaboration)
│   └── WebSocket server, message queue, presence system, delivery guarantees
├── Offline-first / field work (surveys, inspections, notes)
│   └── Sync engine, conflict resolution, outbox pattern, delta sync endpoints
├── Media-heavy (photo/video sharing, streaming)
│   └── Presigned uploads, processing pipeline, CDN, adaptive streaming
└── E-commerce / transactions
    └── Idempotent APIs, payment integration, order state machine, push + email receipts

Backend deployment strategy?
├── Serverless (low traffic, bursty) → AWS Lambda, Vercel, Cloud Functions
├── Containers (moderate, predictable) → Docker + ECS/Cloud Run/Fly.io
├── VPS (full control, budget) → DigitalOcean, Linode, Hetzner
└── BaaS (rapid prototype) → Firebase, Supabase, AWS Amplify
```

## Testing Mobile Backends

- **Device simulation**: Test with different `User-Agent` strings, screen densities, and app versions in headers. Ensure your API responds correctly to version negotiation.
- **Network simulation**: Test with throttled connections (3G, high latency, packet loss). Verify timeouts, retries, and partial responses work correctly.
- **Push testing**: Use platform sandbox environments (APNs sandbox, FCM test). Verify delivery across both platforms. Test notification preferences and opt-outs.
- **Offline scenarios**: Test what happens when the client goes offline mid-request, mid-upload, mid-sync. Verify idempotency keys prevent duplicate writes.
- **Load testing**: Simulate realistic mobile traffic patterns — burst on app open, idle during background, spike during push campaigns. Use tools like k6, Artillery, or Locust.

Interpret requirements thoughtfully and make pragmatic choices that serve mobile users. No two mobile backends are alike. A chat app needs real-time infrastructure. A shopping app needs idempotent transactions. A note-taking app needs conflict-free sync. The backend should be invisible to users — fast, reliable, and always there when they unlock their phone.

**IMPORTANT**: Always design with empathy for the mobile developer consuming your API. They're dealing with complex UI, state management, and platform quirks. Your API should make their life easier, not harder. Clear docs, consistent patterns, meaningful errors, and SDK-friendly response shapes are not optional — they're the difference between a backend developers love and one they work around.

Remember: Mobile backends power the apps people use hundreds of times a day. Every millisecond of latency, every failed sync, every missed notification is felt by a real person holding their phone. Build backends that respect the intimacy of that interaction.
