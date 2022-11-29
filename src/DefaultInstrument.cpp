#include "DefaultInstrument.h"

DefaultInstrument::DefaultInstrument(double start_time, float frequency_input,
                         float amplitude, float duration) : Instrument(),
      frequency(frequency_input) {
  if (duration < MIN_DURATION) {
    qCritical("Too short!");
  }
  dt(start_time);
  auto sustain_level = amplitude * SUSTAIN_RATIO;
  envelope.lengths(ATTACK_TIME, DECAY_TIME, duration - MIN_DURATION, RELEASE_TIME);
  envelope.levels(0, amplitude, sustain_level, sustain_level, 0);
  envelope.curve(CURVATURE);
}

auto DefaultInstrument::get_sample() -> float {
  return oscillator() * envelope();
}

auto DefaultInstrument::add(gam::Scheduler &scheduler, float start_time, float frequency, float amplitude, float duration) const -> float {
  if (duration < MIN_DURATION) {
    duration = MIN_DURATION;
  }
  scheduler.add<DefaultInstrument>(start_time, frequency, amplitude, duration);
  return duration;
}

auto DefaultInstrument::done() -> bool {
  return envelope.done();
}

