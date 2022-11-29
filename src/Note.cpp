#include "Note.h"

Note::Note() : NoteChord() {}

auto Note::get_level() const -> int { return NOTE_LEVEL; };

auto Note::columnCount() const -> int { return NOTE_COLUMNS; };

auto Note::flags(int column, Qt::ItemFlags default_flags) const
    -> Qt::ItemFlags {
  if (column == symbol_column) {
    return Qt::NoItemFlags;
  }
  return default_flags | Qt::ItemIsEditable;
}

void Note::from_json(const QJsonObject &json_note_chord) {
  NoteChord::from_json(json_note_chord);
  instrument = json_note_chord["instrument"].toString();
}

auto Note::to_json(QJsonObject &json_map) const -> void {
  NoteChord::to_json(json_map);
  json_map["instrument"] = instrument;  // instrument;
};

auto Note::data(int column, int role) const -> QVariant {
  if (role == Qt::DisplayRole) {
    if (column == symbol_column) {
      return "♪";
    }
    if (column == numerator_column) {
      return numerator;
    };
    if (column == denominator_column) {
      return denominator;
    };
    if (column == octave_column) {
      return octave;
    };
    if (column == beats_column) {
      return beats;
    };
    if (column == volume_ratio_column) {
      return volume_ratio;
    };
    if (column == tempo_ratio_column) {
      return tempo_ratio;
    };
    if (column == words_column) {
      return words;
    };
    if (column == instrument_column) {
      return instrument;
    }
    NoteChord::error_column(column);
  };
  // no data for other roles
  return {};
}

auto Note::setData(int column, const QVariant &value, int role) -> bool {
  if (role == Qt::EditRole) {
    if (column == numerator_column) {
      return maybeSetNumerator(value.toInt());
    };
    if (column == denominator_column) {
      return maybeSetDenominator(value.toInt());
    };
    if (column == octave_column) {
      octave = value.toInt();
      return true;
    };
    if (column == beats_column) {
      auto parsed = value.toInt();
      // beats cant be negative
      if (parsed >= 0) {
        beats = parsed;
        return true;
      }
      return false;
    };
    if (column == volume_ratio_column) {
      return maybeSetVolumeRatio(value.toFloat());
    };
    if (column == tempo_ratio_column) {
      return maybeSetTempoRatio(value.toFloat());
    };
    if (column == words_column) {
      words = value.toString();
      return true;
    };
    if (column == instrument_column) {
      instrument = value.toString();
      return true;
    };
    NoteChord::error_column(column);
  };
  // dont set any other role
  return false;
}

void Note::test() {
  NoteChord::test();

  QCOMPARE(get_level(), NOTE_LEVEL);
  QCOMPARE(columnCount(), NOTE_COLUMNS);
  QCOMPARE(data(symbol_column, Qt::DisplayRole), "♪");

  test_positive_int_field(beats_column);

  QCOMPARE(data(instrument_column, Qt::DisplayRole), "default");
}

auto Note::pointer_copy_self() -> std::unique_ptr<NoteChord> {
  return std::make_unique<Note>(*this);
}
