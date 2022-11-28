import 'dart:io';

import 'package:aescrypto/aescrypto.dart';
import 'package:aesdatabase/aesdatabase.dart';
import 'package:test/test.dart';

import 'core/core.dart';

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  group("DatabaseEngine Group:", () {
    final DriveSetup driveSetup = DriveSetup();

    final DatabaseEngine databaseEngine = DatabaseEngine(
      driveSetup,
      "passwordKey",
    );

    final List<String> titles = getTitlesDataTest();
    final List<Map<String, dynamic>> rowsData = getRowsDataTest();

    setUpAll(() async {
      await driveSetup.create();
    });

    test("Test (createTable) with duplicate value", () {
      bool isTableCreated;
      Object? error;

      try {
        databaseEngine.createTable([...titles, 'username']);
        isTableCreated = true;
      } catch (e) {
        error = e;
        isTableCreated = false;
      }

      printDebug("""
isTableCreated: $isTableCreated
Error: $error
      """);

      expect(isTableCreated, isFalse);
    });

    test("Test (createTable) first time", () {
      bool isTableCreated;

      try {
        databaseEngine.createTable(titles);
        isTableCreated = true;
      } catch (e) {
        isTableCreated = false;
      }

      printDebug("""
isTableCreated: $isTableCreated
      """);

      expect(isTableCreated, isTrue);
    });

    test("Test (createTable) already created before", () {
      bool isTableCreated;
      Object? error;

      try {
        databaseEngine.createTable(titles);
        isTableCreated = true;
      } catch (e) {
        error = e;
        isTableCreated = false;
      }

      printDebug("""
isTableCreated: $isTableCreated
Error: $error
      """);

      expect(isTableCreated, isFalse);
    });

    test("Test (addRow)", () async {
      bool isDataAdded;

      try {
        for (Map<String, dynamic> row in rowsData) {
          databaseEngine.addRow(row);
        }
        isDataAdded = true;
      } catch (e) {
        isDataAdded = false;
      }

      printDebug("""
isDataAdded: $isDataAdded
      """);

      expect(isDataAdded, isTrue);
    });

    test("Test (addRow) with different data type", () async {
      bool isDataAdded;
      Object? error;

      try {
        databaseEngine.addRow({...rowsData.last, 'isAdmin': 'False'});
        isDataAdded = true;
      } catch (e) {
        error = e;
        isDataAdded = false;
      }

      printDebug("""
isDataAdded: $isDataAdded
Error: $error
      """);

      expect(isDataAdded, isFalse);
    });

    test("Test (addRow) without a column", () async {
      bool isDataAdded;
      Object? error;

      try {
        databaseEngine.addRow(
          rowsData.last.map((key, value) {
            if (key != 'username') return MapEntry(key, value);
            return MapEntry('key', null);
          }),
        );
        isDataAdded = true;
      } catch (e) {
        error = e;
        isDataAdded = false;
      }

      printDebug("""
isDataAdded: $isDataAdded
Error: $error
      """);

      expect(isDataAdded, isFalse);
    });

    test("Test (select) all rows", () async {
      await for (RowModel row in databaseEngine.select()) {
        printDebug("""
index: ${row.index}
row: ${row.items}
      """);

        expect(row.items, equals(rowsData[row.index]));
      }
    });

    test("Test (select) get username/age/gender of all females", () async {
      List<Map<String, dynamic>> data = [];

      await for (RowModel row in databaseEngine.select(
        columnTitles: ['username', 'age', 'gender'],
        items: {'gender': 'female'},
      )) {
        data.add(row.items);

        printDebug("""
index: ${row.index}
row: ${row.items}
      """);

        expect(row.items.length, equals(3));
        expect(row.items.containsKey('username'), isTrue);
        expect(row.items.containsKey('age'), isTrue);
        expect(row.items.containsKey('gender'), isTrue);
      }

      expect(data.length, equals(2));
    });

    test("Test (edit) change his age from 20 to 21", () async {
      int userIndex = 1;
      Map<String, dynamic> user = rowsData[userIndex];

      int newAge = 21;
      Map<String, dynamic> userEdited = {};

      databaseEngine.edit(rowIndex: userIndex, items: {'age': newAge});

      await for (RowModel row in databaseEngine.select(
        items: {'username': user['username']},
      )) {
        userEdited.addAll(row.items);
      }

      printDebug("""
user: $user
userEdited: $userEdited
      """);

      expect(userEdited['username'], equals(user['username']));
      expect(userEdited['password'], equals(user['password']));
      expect(userEdited['age'], equals(newAge));
      expect(userEdited['gender'], equals(user['gender']));
      expect(userEdited['isAdmin'], equals(user['isAdmin']));
    });

    test("Test (removeColumn)", () {
      int countBefore = databaseEngine.countColumn();
      databaseEngine.removeColumn('age');
      int countAfter = databaseEngine.countColumn();

      printDebug("""
countBefore: $countBefore
countAfter: $countAfter
      """);

      expect(countBefore - 1, equals(countAfter));
    });

    test("Test (removeRow)", () async {
      int userIndex = 1;
      Map<String, dynamic> user = rowsData[userIndex];

      int countBefore = databaseEngine.countRow();
      databaseEngine.removeRow(userIndex);
      int countAfter = databaseEngine.countRow();

      bool userExists = false;

      await for (RowModel _ in databaseEngine.select(
        items: {'username': user['username']},
      )) {
        userExists = true;
      }

      printDebug("""
countBefore: $countBefore
countAfter: $countAfter
userExists: $userExists
      """);

      expect(countBefore - 1, equals(countAfter));
      expect(userExists, isFalse);
    });

    test("Test (dump)", () async {
      String outputPath = await databaseEngine.dump();
      bool isExists = File(outputPath).existsSync();

      printDebug("""
outputPath: $outputPath
isExists: $isExists
      """);

      expect(outputPath, equals(addAESExtension(driveSetup.databasePath)));
      expect(isExists, isTrue);
    });

    test("Test (clear)", () {
      databaseEngine.clear();
      bool isClear = databaseEngine.countRow() == 0;

      printDebug("""
isClear: $isClear
      """);

      expect(isClear, isTrue);
    });

    test("Test (load)", () async {
      // Remove all titles to reset and load
      databaseEngine.removeColumn('username');
      databaseEngine.removeColumn('password');
      databaseEngine.removeColumn('gender');
      databaseEngine.removeColumn('isAdmin');

      bool isLoaded = await databaseEngine.load();
      int countRow = databaseEngine.countRow();

      printDebug("""
isLoaded: $isLoaded
countRow: $countRow
      """);

      expect(isLoaded, isTrue);
      expect(countRow, equals(rowsData.length - 1));
    });
  });
}
