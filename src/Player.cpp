#include "Player.h"

Player::Player() { gam::sampleRate(audio_io.fps()); }

void Player::modulate(const TreeNode &node) {
  const auto &note_chord_pointer = node.note_chord_pointer;
  key = key * note_chord_pointer->get_ratio();
  current_volume = current_volume * note_chord_pointer->volume_ratio;
  current_tempo = current_tempo * note_chord_pointer->tempo_ratio;
}

auto Player::get_beat_duration() const -> float {
  return SECONDS_PER_MINUTE / current_tempo;
}

void Player::schedule_note(const TreeNode &node) {
  auto *note_chord_pointer = node.note_chord_pointer.get();
  auto instrument = note_chord_pointer->instrument;
  if (!instrument_map.contains(instrument)) {
    qInfo() << QString("Instrument %1 not defined; using the default instrument!").arg(instrument);
    instrument = "default";
  }
  const auto *sound_pointer = instrument_map[instrument];
  auto true_duration = sound_pointer->add(
    scheduler,
    current_time,
    key * note_chord_pointer->get_ratio(),
    current_volume * note_chord_pointer->volume_ratio,
    get_beat_duration() * static_cast<float>(note_chord_pointer->beats)
  );
  auto final_time = current_time + true_duration;
  if (final_time > total_time) {
    total_time = final_time;
  }
}

void Player::play(const Song &song, const QModelIndex &first_index, int rows) {
  // in case we ended early for some reason, empty first
  key = static_cast<float>(song.frequency);
  current_volume = (FULL_NOTE_VOLUME * static_cast<float>(song.volume_percent)) / PERCENT;
  current_tempo = static_cast<float>(song.tempo);
  current_time = (1.0F * TRANSITION_MILLISECONDS) / MILLISECONDS_PER_SECOND;
  total_time = current_time;

  auto &item = song.const_node_from_index(first_index);
  auto item_position = item.is_at_row();
  auto end_position = item_position + rows;
  auto &parent = item.get_parent();
  parent.check_child_at(item_position);
  parent.check_child_at(end_position - 1);
  auto &sibling_pointers = parent.child_pointers;
  auto level = item.get_level();
  if (level == 1) {
    for (auto index = 0; index < end_position; index = index + 1) {
      auto &sibling = *sibling_pointers[index];
      modulate(sibling);
      if (index >= item_position) {
        for (const auto &nibling_pointer : sibling.child_pointers) {
          schedule_note(*nibling_pointer);
        }
        current_time = current_time +
                       get_beat_duration() * static_cast<float>(sibling.note_chord_pointer->beats);
      }
    }
  } else if (level == 2) {
    auto &grandparent = parent.get_parent();
    auto &uncle_pointers = grandparent.child_pointers;
    auto parent_position = parent.is_at_row();
    grandparent.check_child_at(parent_position);
    for (auto index = 0; index <= parent_position; index = index + 1) {
      modulate(*uncle_pointers[index]);
    }
    for (auto index = item_position; index < end_position; index = index + 1) {
      schedule_note(*sibling_pointers[index]);
    }
  } else {
    TreeNode::error_level(level);
  }
  scheduler.start();
  audio_io.start();
  QThread::msleep(
      static_cast<int>(ceil((total_time + OVERLAP) * MILLISECONDS_PER_SECOND)) +
      TRANSITION_MILLISECONDS*2);
  audio_io.stop();
  scheduler.stop();
  scheduler.update();
  scheduler.reclaim();
}
