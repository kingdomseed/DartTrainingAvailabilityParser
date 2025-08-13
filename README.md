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

