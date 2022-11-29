#include "Instrument.h"

void Instrument::onProcess(gam::AudioIOData &audio_io) {
  while (audio_io()) {
    auto sample_1 = get_sample();
    audio_io.out(0) += sample_1;
    audio_io.out(1) += sample_1;
  }
  if (done()) {
    free();
  }
}
