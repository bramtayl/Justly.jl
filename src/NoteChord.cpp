#include "NoteChord.h"

auto NoteChord::error_column(int column) -> void {
  qCritical("No column %d", column);
}

// TODO: translate
auto NoteChord::headerData(int section, Qt::Orientation orientation, int role)
    -> QVariant {
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    if (section == symbol_column) {
      return {};
    }
    if (section == numerator_column) {
      return "Numerator";
    };
    if (section == denominator_column) {
      return "Denominator";
    };
    if (section == octave_column) {
      return "Octave";
    };
    if (section == beats_column) {
      return "Beats";
    };
    if (section == volume_ratio_column) {
      return "Volume Ratio";
    };
    if (section == tempo_ratio_column) {
      return "Tempo Ratio";
    };
    if (section == words_column) {
      return "Words";
    };
    if (section == instrument_column) {
      return "Instrument";
    };
    NoteChord::error_column(section);
  }
  // no horizontal headers
  // no headers for other roles
  return {};
}

auto NoteChord::get_ratio() const -> float {
  return (1.0F * static_cast<float>(numerator)) / static_cast<float>(denominator) * powf(OCTAVE_RATIO, static_cast<float>(octave));
}

void NoteChord::from_json(const QJsonObject &json_note_chord) {
  numerator = json_note_chord["numerator"].toInt();
  denominator = json_note_chord["denominator"].toInt();
  octave = json_note_chord["octave"].toInt();
  beats = json_note_chord["beats"].toInt();
  volume_ratio = static_cast<float>(json_note_chord["volume_ratio"].toDouble());
  tempo_ratio = static_cast<float>(json_note_chord["tempo_ratio"].toDouble());
  words = json_note_chord["words"].toString();
}

auto NoteChord::to_json(QJsonObject &json_map) const -> void {
  json_map["numerator"] = numerator;
  json_map["denominator"] = denominator;
  json_map["octave"] = octave;
  json_map["beats"] = beats;
  json_map["volume_ratio"] = volume_ratio;
  json_map["tempo_ratio"] = tempo_ratio;
  json_map["words"] = words;
};

auto NoteChord::maybeSetNumerator(int new_numerator) -> bool {
  if (new_numerator > 0) {
    numerator = new_numerator;
    return true;
  }
  return false;
}

auto NoteChord::maybeSetDenominator(int new_denominator) -> bool {
  if (new_denominator > 0) {
    denominator = new_denominator;
    return true;
  }
  return false;
}

auto NoteChord::maybeSetVolumeRatio(float new_volume_ratio) -> bool {
  if (new_volume_ratio > 0) {
    volume_ratio = new_volume_ratio;
    return true;
  }
  return false;
}

auto NoteChord::maybeSetTempoRatio(float new_tempo_ratio) -> bool {
  if (new_tempo_ratio > 0) {
    tempo_ratio = new_tempo_ratio;
    return true;
  }
  return false;
}

void NoteChord::test_simple_int_field(int column) {
  auto previous_value = data(column, Qt::DisplayRole);
  QVERIFY(setData(column, QVariant(2), Qt::EditRole));
  QCOMPARE(data(column, Qt::DisplayRole), 2);
  setData(column, previous_value, Qt::EditRole);
}

void NoteChord::test_positive_int_field(int column) {
  auto previous_value = data(column, Qt::DisplayRole);
  QVERIFY(!(setData(column, QVariant(-1), Qt::EditRole)));
  QVERIFY(setData(column, QVariant(2), Qt::EditRole));
  QCOMPARE(data(column, Qt::DisplayRole), 2);
  setData(column, previous_value, Qt::EditRole);
}

void NoteChord::test_positive_double_field(int column) {
  auto previous_value = data(column, Qt::DisplayRole);
  QVERIFY(!(setData(column, QVariant(-1.0), Qt::EditRole)));
  QVERIFY(setData(column, QVariant(2.0), Qt::EditRole));
  QCOMPARE(data(column, Qt::DisplayRole), 2.0);
  setData(column, previous_value, Qt::EditRole);
}

void NoteChord::test_string_field(int column) {
  auto previous_value = data(column, Qt::DisplayRole);
  QVERIFY(setData(column, QVariant("hello"), Qt::EditRole));
  QCOMPARE(data(column, Qt::DisplayRole), "hello");
  setData(column, previous_value, Qt::EditRole);
}

void NoteChord::test() {
  QCOMPARE(get_ratio(), 1.0F);

  QCOMPARE(headerData(symbol_column, Qt::Horizontal, Qt::DisplayRole), QVariant());
  QCOMPARE(headerData(numerator_column, Qt::Horizontal, Qt::DisplayRole), "Numerator");
  QCOMPARE(headerData(denominator_column, Qt::Horizontal, Qt::DisplayRole), "Denominator");
  QCOMPARE(headerData(octave_column, Qt::Horizontal, Qt::DisplayRole), "Octave");
  QCOMPARE(headerData(beats_column, Qt::Horizontal, Qt::DisplayRole), "Beats");
  QCOMPARE(headerData(volume_ratio_column, Qt::Horizontal, Qt::DisplayRole), "Volume Ratio");
  QCOMPARE(headerData(tempo_ratio_column, Qt::Horizontal, Qt::DisplayRole), "Tempo Ratio");
  QCOMPARE(headerData(words_column, Qt::Horizontal, Qt::DisplayRole), "Words");
  QCOMPARE(headerData(instrument_column, Qt::Horizontal, Qt::DisplayRole), "Instrument");
  QCOMPARE(headerData(-1, Qt::Horizontal, Qt::DisplayRole), QVariant());
  QCOMPARE(headerData(numerator_column, Qt::Vertical, Qt::DisplayRole), QVariant());
  QCOMPARE(headerData(numerator_column, Qt::Horizontal, Qt::DecorationRole), QVariant());

  test_positive_int_field(numerator_column);
  test_positive_int_field(denominator_column);
  test_simple_int_field(octave_column);
  test_positive_double_field(volume_ratio_column);
  test_positive_double_field(tempo_ratio_column);
  test_string_field(words_column);

  QCOMPARE(data(-1, Qt::DisplayRole), QVariant());
  QCOMPARE(data(symbol_column, Qt::DecorationRole), QVariant());

  QCOMPARE(flags(symbol_column, Qt::NoItemFlags), Qt::NoItemFlags);
  QCOMPARE(flags(numerator_column, Qt::NoItemFlags), Qt::NoItemFlags | Qt::ItemIsEditable);
}

