# DEV-0006: Config parser doesn't support shallower tree level after deeper level

- Status: done
- Created: 2024-03-03
- Closed: 2024-03-03
- Type: bug

## Description

Config parser does not support shallower tree level commands after deeper level. Fixed by implementing indentation level detection — indentation width is variable, you just have to be consistent.
