# AGENTS.md

## Project Overview
Flutter mobile application.

Architecture: Feature-based structure  
State management: Riverpod  
Networking: Dio

## Architecture

features/
  feature_name/
    data/
    domain/
    presentation/

presentation/
  pages/
  widgets/
  providers/

Rules:
- UI must not access repositories directly
- UI reads state through Riverpod providers
- Data layer communicates through repositories

## State Management Rules

Use Riverpod for all state management.

Rules:
- Use `NotifierProvider` or `AsyncNotifierProvider`
- Avoid `StatefulWidget` unless necessary
- Business logic must live inside providers
- UI must only watch/read providers

Example pattern:

providers/
  user_provider.dart
  reservation_provider.dart

## File Organization

features/
  feature_name/
    data/
      models/
      repositories/
      datasources/
    domain/
      entities/
      usecases/
    presentation/
      pages/
      widgets/
      providers/

Rules:
- One widget per file
- File name must match class name
- Reusable widgets go in `widgets`

## Networking

Use Dio for API requests.

Rules:
- API calls must go through repository
- Do not call Dio directly from UI
- Repository returns models or entities

## Code Style

Language: Dart

Rules:
- Prefer `const` constructors
- Keep widgets small (<200 lines)
- Follow Dart naming conventions
- Avoid global mutable state

## Development Commands

install dependencies
flutter pub get

run app
flutter run

run tests
flutter test

format code
dart format .

## Workflow Rules

Before writing code:
1. Check existing feature structure
2. Follow existing naming patterns
3. Do not duplicate functionality

When modifying code:
- Keep changes minimal
- Do not refactor unrelated files
- Ensure code compiles