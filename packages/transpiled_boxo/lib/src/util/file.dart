import 'dart:io';

/// Reports whether [filename] exists, including directories and special files.
bool fileExists(String filename) =>
    FileSystemEntity.typeSync(filename, followLinks: false) !=
    FileSystemEntityType.notFound;
