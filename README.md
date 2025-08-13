# Dart Training Availability Parser
A dart script that parses an annoying availability string created by a Google form that we use for choosing message availability for video trainings. 

## Availability Parser

Dart script to convert mixed German/English availability lines into a CSV with one column per message slot and one row per person.

### File
- `scripts/parse_availability.dart`

### Input format
Each line looks like:
`availability segments...`\t`given/middle names`\t`surname`

- Availability segments repeat as German + English, separated by ` / `
- Parser extracts only the German segments matching:
  `HH:MM - HH:MM, (Dienstag|Freitag|Samstag|Tag des Herrn), DD.MM.`
- Lines like `M1\tM2\t...` or other non-matching headers are ignored

### Run
From repo root:

```bash
# From a file → file
dart run scripts/parse_availability.dart --input scripts/availability.txt --output scripts/availability.csv

# From STDIN → STDOUT
cat scripts/availability.txt | dart run scripts/parse_availability.dart > scripts/availability.csv
```

### Output CSV schema
- First column: `Name` (joined from tail fields)
- Remaining columns: one per unique message slot, sorted chronologically by date and start time
- Column labels: `DD.MM HH:MM DOW`, where DOW is `Tue|Fri|Sat|Sun` (derived from German)
- Values: `1` if person is available for that slot, else `0`

### Example
Input line:

```
19:00 - 21:30, Dienstag, 12.08. / Tuesday, August 12	Bob Smith
```

Produces columns like:

```
Name,12.08 19:00 Tue
Bob Smith,1
```

### Notes
- English segments after ` / ` are ignored (they duplicate the German info)
- Whitespace and multiple tabs are handled
- Day mapping: Dienstag→Tue, Freitag→Fri, Samstag→Sat, Tag des Herrn→Sun

# Scripts Directory

This directory contains utility scripts for the Mythic GME Digital project. All scripts are actively maintained and serve specific purposes in the development workflow.

## Script Categories

### 1. Table Validation Scripts
These scripts validate and maintain table data integrity:

- **`check_meaning_table_structure.dart`** - Validates table structure integrity
  - Usage: `dart run scripts/check_meaning_table_structure.dart`
  - Purpose: Ensures all meaning tables have valid structure and required fields
  - Checks: Table metadata, entry formats, language consistency

- **`add_table_type_field.dart`** - Adds type field to tables
  - Usage: `dart run scripts/add_table_type_field.dart`
  - Purpose: Adds table type classification field for categorization

### 2. Build & Release Scripts
Essential scripts for building and releasing the app:

- **`build_macos.sh`** - Builds macOS versions for different distribution channels
  - Usage: `./scripts/build_macos.sh [external|appstore]`
  - Purpose: Creates properly configured builds for App Store or external distribution
  - Options:
    - `external`: Builds for external distribution (Itch.io)
    - `appstore`: Builds for App Store distribution (default)

- **`sign_dmg.sh`** - Signs DMG files for macOS distribution
  - Usage: `./scripts/sign_dmg.sh`
  - Purpose: Code signs DMG files for external distribution
  - Requirements: Valid Apple Developer certificate

- **`generate_release_notes.dart`** - Generates release notes from git commits
  - Usage: `dart run scripts/generate_release_notes.dart --since YYYY-MM-DD [--output filename.md]`
  - Purpose: Creates structured release notes from commit history
  - Features:
    - Categorizes commits by type (feat, fix, docs, etc.)
    - Groups by platform and feature areas
    - Generates markdown-formatted output
  - Example: `dart run scripts/generate_release_notes.dart --since 2025-02-01 --output release_notes_1.5.md`

- **`settings.py`** - DMG configuration for macOS Itch.io releases
  - Purpose: Defines DMG appearance, window settings, and license information
  - Used by: dmgbuild tool during macOS packaging

### 3. Development Tools
Utilities for development workflow:

- **`clean_app_install.sh`** - Cleans app installation for fresh testing
  - Usage: `./scripts/clean_app_install.sh`
  - Purpose: Removes app data for clean installation testing
  - Cleans: Preferences, caches, saved data

- **`create_env_file.sh`** - Creates environment configuration file
  - Usage: `./scripts/create_env_file.sh`
  - Purpose: Sets up development environment variables
  - Creates: `.env` file with required API keys and configuration

## Quick Start

### Generate Release Notes
```bash
# Generate release notes for the last month
dart run scripts/generate_release_notes.dart --since 2025-02-01

# Save to a file
dart run scripts/generate_release_notes.dart --since 2025-02-01 --output release_notes_1.5.md
```

### Build macOS App
```bash
# For App Store (default)
./scripts/build_macos.sh

# For external distribution (Itch.io)
./scripts/build_macos.sh external
```

### Validate Table Structure
```bash
# Check all meaning tables
dart run scripts/check_meaning_table_structure.dart

# Add type fields to tables
dart run scripts/add_table_type_field.dart
```

### Development Utilities
```bash
# Clean app for fresh install testing
./scripts/clean_app_install.sh

# Create environment configuration
./scripts/create_env_file.sh
```

## Requirements

- **Dart Scripts**: Flutter SDK installed and configured
- **Shell Scripts**: Unix-like environment (macOS/Linux)
  - Execute permissions: `chmod +x script_name.sh`
- **Python Config**: Python 3.x (only for `settings.py`)
- **macOS Scripts**: Valid Apple Developer certificate for signing

## Script Details

### Release Notes Generator
The release notes generator analyzes git commit history and produces organized release notes:

- **Commit Categories**: feat, fix, perf, refactor, docs, test, chore, style, build, ci
- **Platform Detection**: Automatically groups iOS, Android, macOS, Windows, Linux changes
- **Feature Grouping**: Groups commits by iCloud, accessibility, localization, UI
- **Conventional Commits**: Supports conventional commit format (`type(scope): message`)

### macOS Build Script
The build script handles different distribution channels:

- **App Store Build**: Uses standard Flutter build with App Store configuration
- **External Build**: Adds `EXTERNAL_DISTRIBUTION=true` flag for Itch.io distribution
- **Output Location**: 
  - App Store: `build/macos/Build/Products/Release/`
  - External: `build/macos/Build/Products/Release/external/`

## Maintenance History

### Recently Removed Scripts (Legacy Migrations)
The following scripts were removed as they completed their purpose:
- Data migration scripts for table format updates
- Schema update scripts for v2 migration
- Event focus modernization scripts
- Field conversion scripts (pairedWith, etc.)

All table data has been successfully migrated to the current format.
