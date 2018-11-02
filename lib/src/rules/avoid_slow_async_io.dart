// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid slow async `dart:io` methods.';

const _details = r'''

**AVOID** using the following asynchronous file I/O methods because they are
much slower than their synchronous counterparts.

* `File.lastModified`
* `File.exists`
* `File.stat`
* `FileSystemEntity.isDirectory`
* `FileSystemEntity.isFile`
* `FileSystemEntity.isLink`
* `FileSystemEntity.type`

**BAD:**
```
import 'dart:async';
import 'dart:io';

Future<Null> someFunction() async {
  var file = new File('/path/to/my/file');
  var now = new DateTime.now();
  if ((await file.lastModified()).isBefore(now)) print('before'); // LINT
}
```

**GOOD:**
```
import 'dart:async';
import 'dart:io';

Future<Null> someFunction() async {
  var file = new File('/path/to/my/file');
  var now = new DateTime.now();
  if (file.lastModifiedSync().isBefore(now)) print('before'); // OK
}
```

''';

const List<String> _fileMethodNames = const <String>[
  'lastModified',
  'exists',
  'stat'
];

const List<String> _fileSystemEntityMethodNames = const <String>[
  'isDirectory',
  'isFile',
  'isLink',
  'type',
];

class AvoidSlowAsyncIo extends LintRule implements NodeLintRuleWithContext {
  AvoidSlowAsyncIo()
      : super(
            name: 'avoid_slow_async_io',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.isEmpty) {
      _checkFileMethods(node);
      return;
    } else {
      _checkFileSystemEntityMethods(node);
      return;
    }
  }

  void _checkFileMethods(MethodInvocation node) {
    DartType type = node.target?.staticType;
    if (DartTypeUtilities.extendsClass(type, 'File', 'dart.io')) {
      if (_fileMethodNames.contains(node.methodName?.name)) {
        rule.reportLint(node);
      }
    }
  }

  void _checkFileSystemEntityMethods(MethodInvocation node) {
    Expression target = node.target;
    if (target is Identifier) {
      Element elem = target?.staticElement;
      if (elem is ClassElement && elem.name == 'FileSystemEntity') {
        if (_fileSystemEntityMethodNames.contains(node.methodName?.name)) {
          rule.reportLint(node);
        }
      }
    }
  }
}
