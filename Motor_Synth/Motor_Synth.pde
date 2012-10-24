/**
 * Motor Synth
 * a resynthesizer that recreates a sound input using motors rather than speakers
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;

class MSineWave extends SineWave implements Comparable<MSineWave> { 

  public MSineWave(float frequency, float amplitude, float sampleRate) {
    super(frequency, amplitude, sampleRate);
  }

  protected float value(float step) {
    return (float)Math.sin(TWO_PI*step);
  }

  // @Override
  public int compareTo(MSineWave other) {
    if (this.amplitude() > other.amplitude()) { 
      return(1);
    } 
    else if (this.amplitude() == other.amplitude()) { 
      return(0);
    }
    else { 
      return(-1);
    }
  }
}


Minim minim;
AudioInput in;
AudioOutput out;
FFT fft; 
Set<MSineWave> wave = new TreeSet<MSineWave>(); 
final int NUMVOICES = 10; // how many voices (motors) will the synth have? 

void setup()
{
  size(1024, 200, P2D);
  frameRate(100);

  minim = new Minim(this);

  // get a mono line-in: sample buffer length of 2048
  // default sample rate is 44100, default bit depth is 16
  in = minim.getLineIn(Minim.MONO, 2048);
  fft = new FFT(in.bufferSize(), in.sampleRate()); 
  fft.window(FFT.HAMMING);

  // get a line out from Minim, default bufferSize is 1024, default sample rate is 44100, bit depth is 16
  out = minim.getLineOut(Minim.STEREO);

  // initialize each element (a sine wave generator) in the set of waves 
  while (wave.size() < NUMVOICES) { 
    wave.add(new MSineWave(0, 0.0, out.sampleRate()));
  }
  // Connect each sine wave generator to the audio output
  for (SineWave s : wave) { 
    out.addSignal(s);
  }
}

void draw()
{
  background(color(218, 138, 145)); 
  stroke(0);

  // perform a forward FFT on the samples in the line input buffer
  fft.forward(in.mix);

  // draw the waveform
  // the values returned by mix.get() will be between -1 and 1,
  // so we need to scale them up to see the waveform
  for (int wave_i = 0; wave_i < in.bufferSize() - 1; wave_i++) {
    line(wave_i, 50 + in.mix.get(wave_i)*height/2, wave_i+1, 50 + in.mix.get(wave_i+1)*height/2);
  }

  // draw a spectrum analysis, frequency on x and amplitude on y
  for (int fft_i = 0; fft_i < fft.specSize(); fft_i++) { 
    // draw the line for frequency band j, scaling it so we can see it a bit better
    float band_freq = float(fft_i)/fft.timeSize()*in.sampleRate();
    if ((band_freq > 20) && (band_freq < 20000)) { // bandpass filter discards inaudible frequencies
      line(fft_i, height, fft_i, height - fft.getBand(fft_i)*height/8);

      //      if (fft.getBand(j) > fft.getBand(loud[0])) {
    }
  }
  //  for (int k = 0; k < 10; k++) { 
  //    print("freq: "); 
  //    print(k); 
  //    print(": "); 
  //    print(float(loud[k])/fft.timeSize()*in.sampleRate()); 
  //    print(" , ");
  //    print("amp: "); 
  //    print(k); 
  //    print(": "); 
  //    print(fft.getBand(loud[k]));
  //    println();
  //}
  //println();
  // play the loudest frequencies, with correct amplitude
  //  for (int p = 0; p < 10; p++) { 
  //    wave[p].setFreq(float(loud[p])/fft.timeSize()*in.sampleRate());
  //    wave[p].setAmp(fft.getBand(loud[p]));
  //  }
}


void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  out.close();
  minim.stop();

  super.stop();
}

