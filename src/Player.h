#pragma once

#include <QString>
#include <QThread>

#include "Song.h"
#include "Instrument.h"

const auto PERCENT = 100;
const auto FRAMES_PER_BUFFER = 256;
const auto SECONDS_PER_MINUTE = 60;
const auto TRANSITION_MILLISECONDS = 100;
const auto MILLISECONDS_PER_SECOND = 1000;
const auto FULL_NOTE_VOLUME = 0.2F;

const DefaultInstrument DUMMY(0.0, 0.0, 0.0, 1.0);

class Player {
 public:
  float key = DEFAULT_FREQUENCY;
  float current_volume = (1.0F * DEFAULT_VOLUME_PERCENT) / PERCENT;
  float current_tempo = DEFAULT_TEMPO;
  float current_time = 0.0;
  float total_time = current_time;

  std::map<const QString, const Instrument *> instrument_map =
      std::map<const QString, const Instrument *>{{"default", (const Instrument *)&DUMMY}};

  gam::Scheduler scheduler;
  gam::AudioDevice default_output =
      gam::AudioDevice(gam::AudioDevice::defaultOutput());
  gam::AudioIO audio_io =
      gam::AudioIO(FRAMES_PER_BUFFER, default_output.defaultSampleRate(),
                   gam::Scheduler::audioCB, &scheduler, 2, 0);

  Player();

  void modulate(const TreeNode &node);
  [[nodiscard]] auto get_beat_duration() const -> float;
  void schedule_note(const TreeNode &node);
  void play(const Song &song, const QModelIndex &first_index, int rows);
};
