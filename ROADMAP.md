# Komoot2GPX v1.0 Roadmap

**Current:** v0.1 (MVP - Core functionality working)  
**Target:** v1.0 (App Store ready, polished experience)

---

## 🎯 v1.0 Vision

A **reliable, polished iOS app** that makes downloading and managing Komoot GPX files effortless. Users should feel confident the app "just works" every time.

---

## 📋 Feature Categories

### P0 - Must Have (v1.0 Blockers)
### P1 - Should Have (High Priority)
### P2 - Nice to Have (Post v1.0)

---

## P0: Must Have for v1.0

### 1. Reliability & Error Handling

| Task | Description | Effort |
|------|-------------|--------|
| **Network retry logic** | Auto-retry failed downloads (2-3 attempts with backoff) | 🟡 Medium |
| **Offline mode** | Clear messaging when offline, queue downloads | 🟢 Low |
| **Better error messages** | User-friendly messages with actionable steps | 🟢 Low |
| **Timeout handling** | Graceful handling of slow/unresponsive requests | 🟡 Medium |
| **File corruption check** | Validate GPX files after save | 🟢 Low |

### 2. User Experience Polish

| Task | Description | Effort |
|------|-------------|--------|
| **Empty states** | Illustrations/helpful text for empty lists | 🟢 Low |
| **Loading states** | Skeleton views, progress indicators | 🟢 Low |
| **Haptic feedback** | Consistent haptics across all interactions | 🟢 Low |
| **Keyboard handling** | Smooth keyboard transitions, focus management | 🟢 Low |
| **Pull to refresh** | Refresh tour list with pull gesture | 🟢 Low |
| **Undo delete** | Snackbar with undo after deleting a tour | 🟡 Medium |

### 3. Tour Management

| Task | Description | Effort |
|------|-------------|--------|
| **Search tours** | Filter tour list by name | 🟢 Low |
| **Sort options** | Sort by date, name, size | 🟢 Low |
| **Bulk delete** | Select multiple tours, delete at once | 🟡 Medium |
| **Tour details** | Basic stats (points, estimated file size) | 🟢 Low |

### 4. Share Extension Improvements

| Task | Description | Effort |
|------|-------------|--------|
| **Handle multiple URLs** | Process multiple shared links | 🟡 Medium |
| **Background processing** | Continue download if user dismisses extension | 🔴 High |
| **Quick actions** | Open main app directly from extension | 🟢 Low |

### 5. App Store Readiness

| Task | Description | Effort |
|------|-------------|--------|
| **App Store assets** | Screenshots, description, keywords, icon variants | 🟡 Medium |
| **Privacy policy** | Required for App Store (even if no data collection) | 🟢 Low |
| **Terms of service** | Basic terms | 🟢 Low |
| **Crash reporting** | Integrate Crashlytics or similar | 🟡 Medium |
| **Analytics** | Basic usage analytics (opt-in) | 🟡 Medium |
| **TestFlight** | Set up beta testing pipeline | 🟢 Low |

---

## P1: Should Have (High Priority)

### 6. GPX Preview Features

| Task | Description | Effort |
|------|-------------|--------|
| **Basic stats** | Distance, elevation gain/loss, point count | 🟡 Medium |
| **Elevation chart** | Simple elevation profile visualization | 🔴 High |
| **Map preview** | Static map with route overlay | 🔴 High |
| **Tour detail view** | Dedicated screen showing all info | 🟡 Medium |

### 7. Enhanced Download Options

| Task | Description | Effort |
|------|-------------|--------|
| **Download quality** | Options for coordinate precision/simplification | 🟡 Medium |
| **Include waypoints** | Download Komoot waypoints if available | 🟡 Medium |
| **Batch download** | Download multiple tours at once | 🔴 High |
| **Download queue** | Visual queue with progress for multiple downloads | 🔴 High |

### 8. File Management

| Task | Description | Effort |
|------|-------------|--------|
| **Export to Files app** | Save copies to user's Files | 🟢 Low |
| **Export to other apps** | Share to mapping apps (Gaia, AllTrails, etc.) | 🟢 Low |
| **iCloud sync** | Sync tour history across devices | 🔴 High |
| **Auto-backup** | Optional backup to iCloud Drive | 🔴 High |

### 9. Customization

| Task | Description | Effort |
|------|-------------|--------|
| **Dark mode** | Full dark mode support | 🟢 Low |
| **App icon choices** | Alternate icons (classic, minimal, etc.) | 🟢 Low |
| **Default save location** | Choose App Group vs. Documents | 🟢 Low |
| **File naming format** | Customize how files are named | 🟢 Low |

---

## P2: Nice to Have (Post v1.0)

### 10. Advanced Features

| Task | Description | Effort |
|------|-------------|--------|
| **Auto-import** | Detect Komoot links in clipboard, suggest download | 🟡 Medium |
| **Widgets** | Home screen widget (recent tours, quick download) | 🟡 Medium |
| **Shortcuts** | Siri Shortcuts integration | 🟡 Medium |
| **Watch app** | View tours on Apple Watch | 🔴 High |
| **Collections** | Organize tours into folders/collections | 🟡 Medium |
| **Notes** | Add personal notes to tours | 🟢 Low |
| **Rating** | Rate tours after completing | 🟢 Low |

### 11. Social & Sharing

| Task | Description | Effort |
|------|-------------|--------|
| **Share tour cards** | Generate image cards for social media | 🟡 Medium |
| **Export as PDF** | Create PDF summary with map + stats | 🔴 High |
| **Share to Strava** | Direct upload to Strava | 🟡 Medium |

### 12. Premium Features (if monetizing)

| Task | Description | Effort |
|------|-------------|--------|
| **Unlimited history** | Free tier: 10 tours, Premium: unlimited | 🟢 Low |
| **Cloud backup** | Premium feature | 🔴 High |
| **Advanced stats** | Premium analytics | 🟡 Medium |
| **Remove ads** | If ad-supported | 🟢 Low |

---

## 📅 Suggested Release Plan

### v0.2 - Polish Sprint (1-2 weeks)
- [ ] All P0 reliability improvements
- [ ] Empty/loading states
- [ ] Haptic feedback pass
- [ ] Pull to refresh
- [ ] Search & sort

### v0.3 - Share Extension (1 week)
- [ ] Background processing
- [ ] Multiple URL handling
- [ ] Quick actions

### v0.4 - Tour Details (2 weeks)
- [ ] Basic GPX stats
- [ ] Tour detail view
- [ ] Undo delete
- [ ] Bulk delete

### v0.5 - App Store Prep (1-2 weeks)
- [ ] Crash reporting
- [ ] Privacy policy
- [ ] App Store assets
- [ ] TestFlight beta

### v1.0 - Release Candidate
- [ ] Beta testing feedback incorporated
- [ ] Final QA pass
- [ ] App Store submission

---

## 🛠 Technical Debt

| Issue | Impact | Fix |
|-------|--------|-----|
| **Code duplication** | ShareExtension copies main app files | Extract to shared framework |
| **No unit tests** | Regression risk | Add tests for downloader, parser |
| **No UI tests** | Manual testing burden | Add critical path UI tests |
| **No CI/CD** | Manual builds | Set up GitHub Actions |
| **Error handling** | Some force unwraps | Replace with proper error handling |

---

## 📊 Success Metrics for v1.0

| Metric | Target |
|--------|--------|
| **Crash-free sessions** | > 99.5% |
| **App Store rating** | > 4.5 stars |
| **Download success rate** | > 95% |
| **Share extension success** | > 90% |
| **User retention (D7)** | > 40% |

---

## 🎨 Design Principles

1. **Native feel** - Follow iOS Human Interface Guidelines
2. **Fast** - App should feel instant, no unnecessary delays
3. **Reliable** - Clear feedback, graceful error handling
4. **Minimal** - Only show what's necessary, hide complexity
5. **Accessible** - Support Dynamic Type, VoiceOver, Reduce Motion

---

## 🔒 Privacy Commitments

- ✅ No personal data collection
- ✅ No analytics by default (opt-in only)
- ✅ No third-party SDKs (except crash reporting)
- ✅ All data stored locally on device
- ✅ No network calls except to Komoot API

---

## 📝 Notes

- **Keep scope tight** - Better to ship fewer features well than many features poorly
- **User feedback** - Use TestFlight to gather feedback before v1.0
- **Iterate** - v1.0 doesn't need everything, just the essentials done well
- **Monetization** - Decide early: free, paid, or freemium

---

**Last updated:** 2026-06-16  
**Next milestone:** v0.2 (Polish Sprint)
