---
test-group: platform
generated: 2026-08-25T08:39:35.501352
---

# `test/platform/`

## `test/platform/platform_io_test.dart`

- IpfsPlatformIO
- isWeb and isIO
- pathSeparator
- writeBytes and readBytes
- readBytes returns null for non-existent file
- exists
- delete file and directory
- createDirectory
- listDirectory
- listDirectory returns empty for non-existent
- getPlatform helper

## `test/platform/platform_web_test.dart`

- IpfsPlatformWeb
- isWeb should be true
- should write and read bytes from IndexedDB
- should check for existence
- should delete files
- should list directory contents via prefix matching
- should delete directory contents
- should get file length
- operatingSystem should be web

