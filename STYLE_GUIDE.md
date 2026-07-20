# Taskboi Style Guide

This document defines the design system for Taskboi. All UI implementations should follow these standards for consistency.

## Colors

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary (Red) | `#DC4C3E` | Primary actions, FAB, focused borders |
| Secondary (Indigo) | `#6366F1` | Secondary actions, accents |

### Priority Colors
| Priority | Hex | Color Name |
|----------|-----|------------|
| Urgent (4) | `#DC4C3E` | Red |
| High (3) | `#F59E0B` | Orange |
| Medium (2) | `#3B82F6` | Blue |
| Low (1) | `#6B7280` | Gray |
| None (0) | `transparent` | - |

### Project Colors Palette
```dart
'#6B7280'  // Gray
'#DC4C3E'  // Red
'#F59E0B'  // Orange
'#10B981'  // Green
'#3B82F6'  // Blue
'#8B5CF6'  // Purple
'#EC4899'  // Pink
'#6366F1'  // Indigo
```

### Surface Colors
| Context | Light Theme | Dark Theme |
|---------|-------------|------------|
| Input fill | `Colors.grey.shade50` | `Colors.grey.shade900` |
| Borders | `Colors.grey.shade200` | `Colors.grey.shade800` |
| Dividers | `Colors.grey.shade200` | `Colors.grey.shade800` |
| Disabled text | `Colors.grey` | `Colors.grey` |

---

## Spacing

### Standard Spacing Scale
Use multiples of 4 for consistency:
- `4` - Minimal gap
- `6` - Tight gap
- `8` - Small gap (chips, compact elements)
- `12` - Medium gap
- `16` - Standard gap (default padding)
- `24` - Large gap (buttons, sections)
- `32` - Extra large gap

### Common Padding Patterns
| Component | Padding |
|-----------|---------|
| Task tile | `horizontal: 16, vertical: 10` |
| Card content | `all: 16` |
| Button | `horizontal: 24, vertical: 14` |
| Input field | `horizontal: 16, vertical: 14` |
| List tile | `horizontal: 16` |
| Chips | `horizontal: 8, vertical: 8` |
| Form header | `fromLTRB(16, 16, 16, 0)` |

### SizedBox Gaps
| Direction | Common Values |
|-----------|---------------|
| Horizontal | `2, 3, 4, 6, 12` |
| Vertical | `6, 8, 12, 16, 24, 32` |

---

## Border Radius

| Usage | Value |
|-------|-------|
| Primary (cards, inputs, buttons) | `12` |
| Secondary (chips, small elements) | `8` |
| Pill-shaped (quick add button) | `20` |
| Bottom sheets | `16` (top corners only) |
| Checkbox area | `10` |
| Drag handle | `2` |

**Pattern:**
```dart
BorderRadius.circular(12)  // Primary
BorderRadius.circular(8)   // Secondary
BorderRadius.vertical(top: Radius.circular(16))  // Bottom sheets
```

---

## Typography

### Text Theme Usage
| Style | Usage |
|-------|-------|
| `headlineLarge` | App title (Taskboi) |
| `titleMedium` | Section headers, user name |
| `titleSmall` | Settings section headers |
| `bodyLarge` | Input fields, primary text |
| `bodyMedium` | Task titles |
| `bodySmall` | Descriptions, metadata |

### Custom Font Sizes
| Size | Usage |
|------|-------|
| `18` | Form titles |
| `14` | Subtask titles |
| `12` | Indicator text, sync status |
| `11` | Metadata, timestamps |

### Text Decorations
- **Bold**: Headers, emphasis
- **Line-through**: Completed tasks
- **Grey color**: Disabled/secondary text

---

## Icons

### Icon Sizes
| Size | Usage |
|------|-------|
| `64` | Large display (login title) |
| `48` | Empty state illustrations |
| `20` | Menu/action icons |
| `18` | Action chips |
| `16` | Quick chip icons |
| `14` | Checkbox checkmark, offline indicator |
| `12` | Metadata row icons (due date, recurring) |

---

## Component Dimensions

### Interactive Elements
| Component | Dimensions |
|-----------|------------|
| Task checkbox | `22 x 22` |
| Subtask checkbox | `20 x 20` |
| Priority circle (form) | `24 x 24` |
| Color picker circle | `32 x 32` |
| Color indicator (list) | `12 x 12` |
| Color dot (metadata) | `6 x 6` |
| Drag handle | `width: 32, height: 4` |

### Loading Indicators
| Context | Size | Stroke Width |
|---------|------|--------------|
| Small (sync) | `12` | `2` |
| Standard | `20` | `2` |
| Large | `24` | `2` |

---

## Elevation

| Component | Elevation |
|-----------|-----------|
| AppBar | `0` (scrolled: `1`) |
| Cards | `0` |
| Buttons | `0` |
| FAB | `2` |

---

## Responsive Design

### Breakpoint
```dart
final isWide = MediaQuery.of(context).size.width >= 800;
```
- **< 800px**: Mobile layout (bottom drawer navigation)
- **>= 800px**: Desktop layout (side drawer navigation)

---

## Special Components

### Checkbox Styling
```dart
Border width: 2
Shape: circular
Completed: grey color with white checkmark
Uncompleted: priority color or Colors.grey.shade400
```

### Dismissible Background
```dart
Background: Colors.red
Icon: Colors.white
Padding: EdgeInsets.only(right: 16)
Alignment: Alignment.centerRight
```

### SnackBar
```dart
behavior: SnackBarBehavior.floating
duration: Duration(seconds: 5)
// Include undo action for destructive operations
```

### Bottom Sheets
```dart
isScrollControlled: true
useSafeArea: true
borderRadius: BorderRadius.vertical(top: Radius.circular(16))
// Adjust for keyboard: EdgeInsets.only(bottom: MediaQuery.viewInsets.bottom)
```

---

## Theme Configuration

```dart
// In app.dart
theme: AppTheme.lightTheme
darkTheme: AppTheme.darkTheme
themeMode: ThemeMode.system  // Respects device theme
useMaterial3: true
```

---

## Quick Reference

### Most Common Values
- **Border radius**: `12`
- **Horizontal padding**: `16`
- **Vertical padding**: `10` (tiles), `14` (inputs/buttons)
- **Icon size (actions)**: `20`
- **Icon size (metadata)**: `12`
- **Gap between elements**: `8` or `12`

### Color Quick Reference
- **Primary action**: `#DC4C3E`
- **Borders (light)**: `Colors.grey.shade200`
- **Borders (dark)**: `Colors.grey.shade800`
- **Disabled**: `Colors.grey`
