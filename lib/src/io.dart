// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.io;

import 'dart:io';

import 'package:linter/src/util.dart';
import 'package:path/path.dart' as p;

/// Visible for testing
IOSink std_err = stderr;

/// Visible for testing
IOSink std_out = stdout;

Iterable<File> collectFiles(String path) {
  List<File> files = [];

  var file = new File(path);
  if (file.existsSync()) {
    files.add(file);
  } else {
    var directory = new Directory(path);
    if (directory.existsSync()) {
      for (var entry
          in directory.listSync(recursive: true, followLinks: false)) {
        var relative = p.relative(entry.path, from: directory.path);

        if (entry is! File || !isLintable(entry)) continue;

        // If the path is in a subdirectory starting with ".", ignore it.
        if (p.split(relative).any((part) => part.startsWith("."))) {
          continue;
        }

        files.add(entry);
      }
    }
  }

  return files;
}

bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);
bool isLintable(FileSystemEntity file) =>
    isDartFile(file) || isPubspecFile(file);
bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));