# BestCut

잘 나온 사진만 남기는 iPhone 사진 정리 앱입니다.

여행이나 주말처럼 기간을 고르면 그 기간의 사진을 iPhone 안에서 분석해서, 비슷한 사진은 한 묶음으로 모으고 묶음마다 가장 잘 나온 사진을 추천합니다. 사용자는 스와이프로 남길 사진만 고르면 됩니다.

## 주요 기능

- **비슷한 사진 묶기**: 같은 장면을 연달아 찍은 사진과 스크린샷을 한 묶음으로 모읍니다.
- **품질 표시**: 흔들림, 초점 나감, 너무 어둡거나 밝은 사진, 눈 감은 사진을 표시합니다.
- **베스트 컷 추천**: 묶음마다 가장 선명한 사진을 미리 골라 둡니다.
- **짧은 동영상 정리**: 실수로 찍힌 짧은 영상을 모아 보여 줍니다.
- **나란히 비교 / 스와이프로 고르기**: 두 장을 함께 확대해 비교하고, 오른쪽은 남기기, 왼쪽은 지울 후보로 넘깁니다.
- **도시별 자동 나누기**: 여러 도시를 다녀온 여행을 도시별 구간으로 나누고 폴더로 묶습니다.
- **결과 요약**: "1,284장 → 212장, 3.8GB 확보"처럼 정리 결과를 보여 주고, 고른 사진은 "[여행 이름] 베스트" 앨범에 담습니다.

사진은 기기 밖으로 나가지 않습니다. 로그인, 광고, 추적이 없습니다.

## 구조

```
TripPick/                  # SwiftUI 앱 (Home, Swipe, Review, Summary, Trips, Settings, Onboarding)
Packages/TripPickCore/     # 핵심 로직 Swift 패키지 (분석, 묶기, 추천, 규칙, 세션, 장소, 저장)
scripts/                   # 빌드·테스트·아이콘·번역 스크립트
docs/release/              # App Store 문구, 개인정보 처리방침, iPhone 실행 방법
docs/superpowers/          # 설계 문서와 구현 계획
```

## 개발 환경

- Xcode (iOS 26.0 이상 대상), Swift 6
- 프로젝트 파일: `TripPick.xcodeproj` (앱 표시 이름은 BestCut)

## 빌드와 테스트

```bash
scripts/core-test.sh   # TripPickCore 단위 테스트
scripts/app-build.sh   # iPhone 17 시뮬레이터용 앱 빌드
```

개발자 계정 없이 본인 iPhone에 설치하는 방법은 [docs/release/run-on-iphone.md](docs/release/run-on-iphone.md)에 있습니다.

## 문서

- [App Store 소개 문구](docs/release/app-store-listing.md)
- [개인정보 처리방침](docs/release/privacy-policy.md)
