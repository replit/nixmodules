const notes = {
  C: 261.63,
  "C#": 277.18,
  D: 293.66,
  "D#": 311.13,
  E: 329.63,
  F: 349.23,
  "F#": 369.99,
  G: 392.0,
  "G#": 415.3,
  A: 440.0,
  "A#": 466.16,
  B: 493.88,
};

exports.play = (note, octave = 4, duration = 1) => {
  note = note.toUpperCase();
  if (!notes[note]) {
    throw new Error("Invalid note: " + note);
  }

  if (duration <= 0) return;

  exports.sound(notes[note] * Math.pow(2, octave - 4), duration);
};

let c;
const type = "sine";

exports.sound = (freq, duration = 1) => {
  if (duration <= 0) return;

  if (!c) {
    c = new (window.AudioContext || window.webkitAudioContext)();
  }

  let offset = c.currentTime + 0;
  let oscillator = c.createOscillator();
  let gainNode = c.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(c.destination);
  oscillator.type = type;

  oscillator.frequency.value = freq;
  gainNode.gain.setValueAtTime(0, offset);
  gainNode.gain.linearRampToValueAtTime(1, offset + 0.01);

  oscillator.start(offset);
  gainNode.gain.exponentialRampToValueAtTime(0.01, offset + length);
  oscillator.stop(offset + length);
};

exports.close = () => {
  if (c) c.close();
};
