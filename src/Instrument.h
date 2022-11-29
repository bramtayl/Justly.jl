#pragma once

#include "Gamma/AudioIO.h"
#include "Gamma/Envelope.h"
#include "Gamma/Oscillator.h"
#include "Gamma/Scheduler.h"

class Instrument : public gam::Process<gam::AudioIOData> {
 public:
  virtual auto add(gam::Scheduler &scheduler, float start_time, float frequency, float amplitude, float duration) const -> float = 0;
  virtual auto get_sample() -> float = 0;
  virtual auto done() -> bool = 0;
  void onProcess(gam::AudioIOData &audio_io) override;
};
