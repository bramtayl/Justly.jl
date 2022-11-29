#pragma once

#include <QtGlobal>

#include "Instrument.h"

const auto FREQUENCY_RATIO = 1;
const auto AMPLITUDE_RATIO = 0.4F;
const auto HARMONICS = 8;
const auto OVERLAP = 0.1F;

const auto ATTACK_TIME = 0.05F;
const auto DECAY_TIME = 0.2F;
const auto RELEASE_TIME = 0.1F;
const auto SUSTAIN_RATIO = 0.6F;
const auto CURVATURE = -4;
const auto MIN_SUSTAIN = 0.01F;
const auto MIN_DURATION = ATTACK_TIME + DECAY_TIME + MIN_SUSTAIN + RELEASE_TIME - OVERLAP;

class DefaultInstrument : public Instrument {
 public:
  DefaultInstrument(double start_time, float frequency, float amplitude,
               float duration);
  const float frequency;
  gam::DSF<> oscillator = gam::DSF<>(frequency, FREQUENCY_RATIO, AMPLITUDE_RATIO, HARMONICS);
  gam::Env<4> envelope;
  auto get_sample() -> float override;
  auto add(gam::Scheduler &scheduler, float start_time, float frequency, float amplitude, float duration) const -> float override;
  auto done() -> bool override;
};

