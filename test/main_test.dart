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

    setUpAll(() {
      driveSetup.create();
    });

    test("Test (createTable) with duplicate value", () async {
      bool isTableCreated;
      Object? error;

      try {
        await databaseEngine.createTable([...titles, 'username']);
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

    test("Test (createTable) first time", () async {
      bool isTableCreated;

      try {
        await databaseEngine.createTable(titles);
        isTableCreated = true;
      } catch (e) {
        isTableCreated = false;
      }

      printDebug("""
isTableCreated: $isTableCreated
      """);

      expect(isTableCreated, isTrue);
    });

    test("Test (createTable) already created before", () async {
      bool isTableCreated;
      Object? error;

      try {
        await databaseEngine.createTable(titles);
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

    test("Test (insert)", () async {
      bool isDataAdded;

      try {
        for (Map<String, dynamic> row in rowsData) {
          await databaseEngine.insert(
            rowIndex: databaseEngine.countRowSync(),
            items: row,
          );
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

    test("Test (insert) with different data type", () async {
      bool isDataAdded;
      Object? error;

      try {
        await databaseEngine.insert(
          items: {...rowsData.last, 'isAdmin': 'False'},
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

    test("Test (insert) without a column", () async {
      bool isDataAdded;
      Object? error;

      try {
        await databaseEngine.insert(
          items: rowsData.last.map((key, value) {
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

    test("Test (select) some columns / rows", () async {
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

    test("Test (edit)", () async {
      int userIndex = 1;
      Map<String, dynamic> user = rowsData[userIndex];

      int newAge = 21;
      Map<String, dynamic> userEdited = {};

      await databaseEngine.edit(rowIndex: userIndex, items: {'age': newAge});

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

    test("Test (removeColumn)", () async {
      int countBefore = databaseEngine.countColumnSync();
      await databaseEngine.removeColumn('age');
      int countAfter = databaseEngine.countColumnSync();

      printDebug("""
countBefore: $countBefore
countAfter: $countAfter
      """);

      expect(countBefore - 1, equals(countAfter));
    });

    test("Test (removeRow)", () async {
      int userIndex = 1;
      Map<String, dynamic> user = rowsData[userIndex];

      int countBefore = databaseEngine.countRowSync();
      await databaseEngine.removeRow(userIndex);
      int countAfter = databaseEngine.countRowSync();

      bool userExists = false;

      await for (RowModel row in databaseEngine.select(
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

      expect(outputPath, equals(addExtension(driveSetup.databasePath)));
      expect(isExists, isTrue);
    });

    test("Test (clear)", () async {
      await databaseEngine.clear();
      bool isClear = databaseEngine.countRowSync() == 0;

      printDebug("""
isClear: $isClear
      """);

      expect(isClear, isTrue);
    });

    test("Test (dump)", () async {
      // Remove all titles to reset and load
      databaseEngine.removeColumn('username');
      databaseEngine.removeColumn('password');
      databaseEngine.removeColumn('gender');
      databaseEngine.removeColumn('isAdmin');

      bool isLoaded = await databaseEngine.load();
      int countRow = databaseEngine.countRowSync();

      printDebug("""
isLoaded: $isLoaded
countRow: $countRow
      """);

      expect(isLoaded, isTrue);
      expect(countRow, equals(rowsData.length - 1));
    });
  });
}
