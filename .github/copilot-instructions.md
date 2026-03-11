# Flutter Architecture Rules

This project follows a feature-based clean architecture with strict UI composition rules.

Copilot should follow these rules when generating code.


--------------------------------------------------
Architecture
--------------------------------------------------

Project structure:

lib/
  core/
  features/

features/
  feature_name/
    data/
    domain/
    presentation/

presentation/
  screens/
  widgets/
  viewmodels/

Each feature must contain its own layers.

Example:

features/
  map/
    data/
    domain/
    presentation/


--------------------------------------------------
Layer Responsibilities
--------------------------------------------------

data/

Responsible for:
- API calls
- database access
- models
- repository implementations

domain/

Responsible for:
- entities
- repository interfaces
- usecases

presentation/

Responsible for:
- UI
- viewmodels
- widget composition


--------------------------------------------------
Screen Rules
--------------------------------------------------

Screen files must contain minimal code.

Screens are responsible only for composing widgets using the feature BaseScaffold.

Screens must NOT contain:

- UI layout logic
- large build methods
- business logic
- API calls

Screens should usually be less than 25 lines.


Example screen:

return MapBaseScaffold(
  top: MapTopWidget(),
  body: MapBodyWidget(),
  bottom: MapBottomWidget(),
)


--------------------------------------------------
BaseScaffold Rules
--------------------------------------------------

Do not use Scaffold directly inside screens.

Each feature must define its own BaseScaffold.

BaseScaffold constructor parameters must use semantically meaningful names
that describe the content, not generic layout positions.

Do NOT use generic names like top, body, bottom.

Use names that describe what the widget represents.

Example:

// BAD
return HomeBaseScaffold(
  top: HomeMyReservationWidget(),
  body: HomeMachineSectionWidget(),
  bottom: HomeMachineSectionWidget(),
)

// GOOD
return HomeBaseScaffold(
  myReservation: HomeMyReservationWidget(),
  washerSection: HomeMachineSectionWidget(),
  dryerSection: HomeMachineSectionWidget(),
)

Examples:

MapBaseScaffold
AuthBaseScaffold
HomeBaseScaffold


Feature BaseScaffold example layout:

top
body
bottom


Example:

return MapBaseScaffold(
  top: MapTopWidget(),
  body: MapBodyWidget(),
  bottom: MapBottomWidget(),
)


--------------------------------------------------
UI Composition
--------------------------------------------------

UI must be split into small widgets.

Rules:

- Screens compose widgets
- Widgets contain UI
- ViewModels contain logic

Avoid large widgets.


If a build method becomes large:

Extract UI into smaller widgets.


Example structure:

presentation/
  screens/
    map_screen.dart

  widgets/
    map_top_widget.dart
    map_body_widget.dart
    map_bottom_widget.dart

  viewmodels/
    map_view_model.dart


--------------------------------------------------
Widget Rules
--------------------------------------------------

Widgets should:

- be small
- be reusable
- receive data through constructor

Prefer StatelessWidget.

Use StatefulWidget only when local UI state is required.


--------------------------------------------------
Code Duplication Rules
--------------------------------------------------

Avoid duplicate code.

If duplicate logic appears:

1. Extract reusable widget
2. Extract utility function
3. Extract service


Reusable locations:

UI reuse:
core/widgets/

logic reuse:
core/utils/

shared services:
core/services/


--------------------------------------------------
Naming Rules
--------------------------------------------------

Screens:
*_screen.dart

Widgets:
*_widget.dart

ViewModels:
*_view_model.dart

Feature scaffolds:
*_base_scaffold.dart


Examples:

map_screen.dart
map_top_widget.dart
map_view_model.dart
map_base_scaffold.dart


--------------------------------------------------
Folder Example
--------------------------------------------------

lib/
  core/
    ui/
      base_scaffold.dart

  features/
    map/
      data/
      domain/

      presentation/
        screens/
          map_screen.dart

        widgets/
          map_base_scaffold.dart
          map_top_widget.dart
          map_body_widget.dart
          map_bottom_widget.dart

        viewmodels/
          map_view_model.dart


--------------------------------------------------
Copilot Behavior Expectations
--------------------------------------------------

When generating Flutter code:

- Follow feature-based architecture
- Keep screens minimal
- Use feature BaseScaffold
- Split UI into widgets
- Avoid duplicate code
- Respect folder structure
- Use constructor-based widget composition


--------------------------------------------------
Screen Pattern (Thin Screen Pattern)
--------------------------------------------------

Screens should be thin composition layers.

Example:

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapBaseScaffold(
      top: const MapTopWidget(),
      body: const MapBodyWidget(),
      bottom: const MapBottomWidget(),
    );
  }
}


--------------------------------------------------
Local Widgets Pattern (part + local_widgets/)
--------------------------------------------------

When a widget file contains multiple private sub-widget classes,
extract them into a local_widgets/ subfolder using Dart's part directive.

This keeps private widgets co-located and organized
without breaking encapsulation.

Rules:

- Create a local_widgets/ folder inside the widgets/ folder
- Each file in local_widgets/ must declare: part of '../parent_widget.dart';
- The parent widget file must declare: part 'local_widgets/filename.dart';
- Private classes (_ClassName) remain private to the parent library
- No imports are needed in part files — they share the parent's imports

When to use:

Use this pattern when a widget file has 2 or more private sub-widgets
that make the file long or hard to read.

Folder structure example:

widgets/
  alarm_list_widget.dart          ← declares part directives
  local_widgets/
    alarm_date_section.dart       ← part of '../alarm_list_widget.dart'
    alarm_date_divider.dart       ← part of '../alarm_list_widget.dart'

Parent file example:

import 'package:flutter/material.dart';

part 'local_widgets/alarm_date_section.dart';
part 'local_widgets/alarm_date_divider.dart';

class AlarmListWidget extends StatelessWidget {
  const AlarmListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateSection(...),  // private class from local_widgets/
      ],
    );
  }
}

Part file example:

part of '../alarm_list_widget.dart';

class _DateSection extends StatelessWidget {
  // no imports needed — shares parent's imports
}

Naming rules for local_widgets/ files:

Use descriptive names that represent the widget's role.

Examples:

alarm_date_section.dart
alarm_date_divider.dart
reservation_card.dart
reservation_body.dart