void tableCreationValidator(List<String> columnTitles) {
  if (columnTitles.isEmpty) {
    throw Exception("Table not created yet");
  }
}

void rowIndexValidator(int rowIndex, List<dynamic> rows) {
  try {
    rows[rowIndex];
  } on RangeError {
    throw Exception("Row index $rowIndex does not exist");
  }
}

void rowTypeValidator(
  List<dynamic> row,
  List<String> columnTitles,
  List<dynamic> rows,
) {
  final List<dynamic> firstRow;

  try {
    firstRow = rows[0];
  } on RangeError {
    // No previous row to check last item type
    return;
  }

  for (int index = 0; index < row.length; index++) {
    final Type itemType = row[index].runtimeType;
    final Type expectedType = firstRow[index].runtimeType;

    if (itemType != expectedType) {
      final String title = columnTitles[index];
      throw Exception(
        "$title type expected $expectedType, but got $itemType",
      );
    }
  }
}

void attachmentValidator(bool hasAttachments) {
  if (!hasAttachments) {
    throw Exception("Attachment option is disabled");
  }
}

void backupValidator(bool hasBackup) {
  if (!hasBackup) {
    throw Exception("Backup option is disabled");
  }
}
