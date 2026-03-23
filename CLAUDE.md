# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Android puzzle application built with Flutter. Primary target devices are Google Pixel 9a and Pixel 10.

## Build & Run Commands

- `flutter run` — run the app (debug mode)
- `flutter run --release` — run in release mode
- `flutter build apk` — build release APK
- `flutter build appbundle` — build Android App Bundle for Play Store
- `flutter test` — run all tests
- `flutter test test/path_to_test.dart` — run a single test file
- `flutter analyze` — run static analysis (linter)
- `flutter pub get` — install dependencies

## Architecture

- **Target platform:** Android only (Pixel 9a, Pixel 10)
- **Framework:** Flutter (Dart)
- **Min SDK:** Target API levels appropriate for Pixel 9a/10 (Android 14+)
