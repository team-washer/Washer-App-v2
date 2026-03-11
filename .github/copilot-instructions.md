# Flutter Architecture Rules

## Feature Structure

features/
  feature_name/
    data/
    domain/
    presentation/

presentation/
  pages/
  widgets/
  viewmodels/


## Scaffold Rules

Do not use Scaffold directly in pages.

Each feature must define its own BaseScaffold.

Example:

MapBaseScaffold
AuthBaseScaffold
HomeBaseScaffold


## Page Structure

Pages must use the feature BaseScaffold.

Example:

return MapBaseScaffold(
  top: TopWidget(),
  body: BodyWidget(),
  bottom: BottomWidget(),
)


## Layout Slots

Feature scaffolds may define layout slots such as:

top
body
bottom

The page provides widgets for these slots.


## Code Reuse

If logic or widgets are duplicated:

Extract them into:

core/widgets
core/utils
core/services


## UI Composition

Pages should not contain large UI code.

UI must be split into widgets.


## Naming Rules

Pages:
*_screen.dart

Widgets:
*_widget.dart

ViewModels:
*_viewmodel.dart

Feature scaffolds:
*_base_scaffold.dart