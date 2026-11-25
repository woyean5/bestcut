# 도시별 나누기 + 폴더 + 사용법 화면 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 여러 도시를 다녀온 기간을 도시별 정리로 자동 제안·분할해 폴더로 묶고(사진 앱에도 폴더), 첫 실행 시 사용법 화면을 보여 준다.

**Architecture:** 하루별 도시 판단과 구간 만들기는 `TripPickCore/Places/TripSplitter.swift`의 순수 함수로 두고 테스트한다. 도시 이름은 기존 `PlaceNaming`에 나라 이름을 더해 재사용한다. 폴더는 SwiftData `FolderRecord`와 `TripRecord.folderID`로 저장하고, 사진 앱 폴더는 `PhotoLibrary.addToAlbum(... inFolder:)`로 만든다.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, PhotoKit(`PHCollectionList`), MapKit 역지오코딩(기존)

**Spec:** `docs/superpowers/specs/2026-11-26-folders-split-welcome-design.md`

## Global Constraints
- 기존 전역 규칙(iOS 26, 네 언어 번역 동시 커밋, 사용자가 정하지 않은 사진은 지우지 않음)을 그대로 따른다.
- 새로 외부로 보내는 정보 없음. 장소 좌표만 기존 애플 지도 조회로 보낸다.
- 폴더는 한 단계만(폴더 안 폴더 없음). 폴더를 지워도 사진은 지우지 않는다.

## Review Focus
1. 위치 정보가 없는 사진만 있는 기간 → 나누기 제안 없이 지금처럼 하나로 정리. → Task 1 `noLocationsNoSplit`
2. 한 도시만 있는 기간 → 제안 없음. → Task 1 `singleCityNoSplit`
3. 하루 당일치기(예: 교토 하루) → 이웃 구간에 합쳐져 제안이 과하게 쪼개지지 않음. → Task 1 `oneDayTripIsMerged`
4. 위치 사진이 없는 날(실내 사진만) → 앞 구간에 붙음, 날짜에 빈틈 없음. → Task 1 `daysWithoutLocationJoinPrevious`
5. 폴더 삭제 → 안의 정리 기록만 지우고 사진·앨범은 그대로. → Task 3에서 `deleteFolder`가 `library`를 호출하지 않음을 코드로 보장(라이브러리 의존 없음).

---

### Task 1: 하루별 도시 판단과 구간 만들기 (core)

**Files:** Create `Packages/TripPickCore/Sources/TripPickCore/Places/TripSplitter.swift`; Modify `Places/TripTitle.swift`(PlaceNaming에 `place(for:locale:)` 기본 구현), `Places/AppleMapsPlaceNamer.swift`; Test `Tests/TripPickCoreTests/TripSplitterTests.swift`

**Interfaces — Produces:**
- `public struct PlaceName: Sendable, Equatable { city: String; country: String? }`
- `PlaceNaming.place(for: Coordinate, locale: Locale) async -> PlaceName?` (기본 구현: `cityName`으로 만들고 country nil)
- `public struct CitySegment: Sendable, Equatable { city: String; country: String?; start: Date; end: Date /* 마지막 날 0시 */; photoCount: Int }`
- `public enum TripSplitter { static func segments(days: [DayCity], calendar: Calendar) -> [CitySegment]; static func suggest(items: [MediaItem], namer: PlaceNaming, locale: Locale, calendar: Calendar = .current) async -> [CitySegment] }` — 2구간 이상일 때만 결과, 아니면 빈 배열
- `public struct DayCity: Sendable { day: Date; city: String?; country: String?; count: Int }`

규칙(spec): 하루의 도시 = 그날 위치 사진이 가장 많은 도시. 위치 없는 날은 앞 구간(첫날이면 다음 구간)에 붙임. 연속 같은 도시를 한 구간으로. 하루짜리 구간 또는 사진 3장 미만 구간은 사진이 더 많은 이웃 구간에 합침(반복). 2구간 이상일 때만 반환.

`suggest`: 위치 사진을 `PlaceClusterer.clusters`로 묶고 3장 이상 클러스터만 `namer.place`로 이름을 얻어, 각 사진을 가장 가까운 이름 있는 클러스터(25km 이내)의 도시로 본다. 날짜별로 세어 `segments(days:)`.

- [ ] 실패 테스트: `twoCitiesSplitByDay`(오사카 3일·도쿄 3일 → 2구간, 날짜 정확), `singleCityNoSplit`, `noLocationsNoSplit`, `oneDayTripIsMerged`(오사카 3일·교토 1일·도쿄 3일 → 2구간), `daysWithoutLocationJoinPrevious`, `suggestUsesNamer`(가짜 namer로 오사카/도쿄 좌표)
- [ ] 구현 → 전체 테스트 통과 → 커밋 `feat(core): split a date range into city segments`

### Task 2: 사진 앱 폴더 (core)

**Files:** Modify `Library/PhotoLibrary.swift`, `Library/PhotoKitLibrary.swift`, `Session/TripSession.swift`, `Tests/.../Fakes.swift`; Test `TripSessionTests.swift`

**Interfaces — Produces:**
- `PhotoLibrary.addToAlbum(named: String, add: [String], remove: [String], inFolder folder: String?) async throws` (기존 3인자 메서드는 protocol extension에서 `inFolder: nil`로 호출)
- `TripSession.finalize(bestAlbum:screenshotAlbum:deleteCandidates:folder: String? = nil)`
- Fake: `albumFolders: [String: String]`

PhotoKit: 같은 이름의 최상위 `PHCollectionList`(폴더)를 찾고 없으면 `PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle:)`로 만든 뒤, 앨범을 새로 만들 때 그 폴더에 `addChildCollections`. 이미 있는 앨범은 폴더 안에서 먼저 찾는다.

- [ ] 실패 테스트 `finalizePutsAlbumsInFolder`: `folder: "일본 여행"`으로 finalize → `lib.albumFolders["오사카 Best"] == "일본 여행"`
- [ ] 구현 → 통과 → 커밋 `feat(core): albums can go into a Photos folder`

### Task 3: 폴더 저장과 목록·나누기 화면 (app)

**Files:** Modify `Persistence/Records.swift`(core: `FolderRecord`, `TripRecord.folderID: UUID?`, 스키마), `TripPick/Trips/TripListView.swift`, `TripPick/Trips/NewTripView.swift`, `TripPick/Summary/SummaryView.swift`, `TripPick/Home/TripHomeView.swift`; Create `TripPick/Trips/FolderView.swift`, `TripPick/Trips/SplitSuggestionView.swift`; Test `PersistenceTests.swift`(`foldersPersistWithTrips`)

- `@Model public final class FolderRecord { @Attribute(.unique) id: UUID; name: String; createdAt: Date }`
- 목록: 폴더 행(폴더 아이콘, 이름, 구간 수) → `FolderView`(구간 목록, 각 행에 날짜) → 기존 `TripFlowView`. 폴더 없는 정리는 지금처럼.
- 새 정리: 사진을 불러온 뒤 `TripSplitter.suggest` 결과가 있으면 이름 칸 아래에 제안 카드("도시별로 나눌까요?" + 폴더 이름 + 구간 목록 + [나눠서 정리] / [하나로 정리]). 나눠서 정리 → FolderRecord 1개 + 구간마다 TripRecord(name = 도시, folderID) 생성 후 닫기.
- 폴더 이름: 모든 구간 country가 같으면 `L10n "\(country) Trip"`, 아니면 `TripTitle.join(cities)` + `"\(…) Trip"`.
- 결과 화면: 정리가 폴더 안이면 `finalize(folder: 폴더 이름)`.
- 폴더 삭제: 목록에서 밀어서 삭제 → 안의 TripRecord와 FolderRecord 삭제(사진·앨범 그대로).
- [ ] 저장 테스트 → 빌드 → 커밋 `feat(app): folders and split suggestion`

### Task 4: 처음 사용법 화면 (app)

**Files:** Create `TripPick/Onboarding/WelcomeView.swift`; Modify `TripPickApp.swift`(RootView), `Settings/SettingsView.swift`

- `@AppStorage("hasSeenWelcome") = false`. false면 RootView가 권한 화면보다 먼저 `WelcomeView`를 보여 주고 "계속"에서 true.
- 행 4개: `square.stack.3d.up` 비슷한 사진은 한 묶음으로 / `camera.metering.unknown` 흔들리거나 어두운 사진 표시 / `hand.draw` 스와이프로 빠르게 고르기 / `lock.shield` 사진은 iPhone 밖으로 나가지 않아요. 각 행은 제목 + 한 줄 설명.
- 설정: "사용법 보기" 버튼 → 같은 화면을 시트로.
- [ ] 빌드 → 커밋 `feat(app): welcome screen`

### Task 5: 번역, 확인, 설치

- [ ] `l10n.py missing` → 네 언어 번역 → `generate`
- [ ] 시뮬레이터: 뉴욕·워싱턴 사진(이틀)으로 나누기 제안 → 나눠서 정리 → 폴더 목록 → 구간 열기 → 결과에서 앨범 만들기 → 사진 앱 DB에서 폴더 안 앨범 확인. 앱 데이터를 지우고 사용법 화면 확인.
- [ ] 코어 테스트 전체 통과, iPhone 설치, 커밋
