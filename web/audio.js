/* Web playback for LINE GAP. The desktop edition keeps Godot's audio mixer. */
(() => {
  'use strict';
  const effectNames = ['collect', 'hit', 'shatter', 'death'];
  const music = new Audio(new URL('audio/bumba-crossing.mp3', document.baseURI));
  music.loop = true;
  music.preload = 'metadata';
  let context, musicGain, sfxLimiter, musicMeter, sfxMeter, outputMeter;
  let enabled = false;
  let activated = false;
  let error = '';
  const buffers = new Map();
  const voices = new Map(effectNames.map(name => [name, []]));
  const requested = Object.fromEntries(effectNames.map(name => [name, 0]));
  const played = { ...requested };
  const downloads = new Map(effectNames.map(name => [name,
    fetch(new URL(`audio/${name}.wav`, document.baseURI)).then(response => {
      if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
      return response.arrayBuffer();
    }).catch(fail)
  ]));

  function fail(reason) {
    error = String(reason && reason.message || reason);
    console.error('LINE GAP audio:', error);
  }

  function limiter(threshold) {
    const node = context.createDynamicsCompressor();
    node.threshold.value = threshold;
    node.knee.value = 0;
    node.ratio.value = 20;
    node.attack.value = 0;
    node.release.value = 0.06;
    return node;
  }

  function initialize() {
    if (context) return;
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioContextClass) throw new Error('This browser does not support Web Audio.');
    context = new AudioContextClass({ latencyHint: 'interactive' });
    const master = limiter(-1);
    // The compressor smooths overlaps; a final ceiling also catches its transients.
    const ceiling = context.createWaveShaper();
    ceiling.curve = Float32Array.from({ length: 4097 }, (_, index) =>
      Math.max(-0.89, Math.min(0.89, index / 2048 - 1)));
    outputMeter = context.createAnalyser();
    outputMeter.fftSize = 2048;
    master.connect(ceiling).connect(outputMeter).connect(context.destination);
    sfxLimiter = limiter(-1);
    sfxMeter = context.createAnalyser();
    sfxMeter.fftSize = 2048;
    sfxLimiter.connect(sfxMeter).connect(master);
    musicGain = context.createGain();
    musicGain.gain.value = Math.pow(10, -3 / 20);
    musicMeter = context.createAnalyser();
    musicMeter.fftSize = 2048;
    context.createMediaElementSource(music).connect(musicGain).connect(musicMeter).connect(master);
    for (const name of effectNames) {
      buffers.set(name, downloads.get(name).then(data => {
        if (!data) throw new Error(`Could not load ${name}.wav`);
        return context.decodeAudioData(data);
      }));
    }
  }

  function startMusic() {
    if (!enabled || !activated) return;
    try {
      initialize();
      if (context.state === 'suspended') context.resume().catch(fail);
      if (music.paused) music.play().catch(fail);
    } catch (reason) { fail(reason); }
  }

  function setMusicEnabled(value) {
    enabled = Boolean(value);
    if (enabled) startMusic();
    else music.pause(); // Preserve the position; sound effects have their own path.
  }

  function unlock(event) {
    if (!event.isTrusted || !event.target.closest('#canvas')) return;
    activated = true;
    try {
      initialize();
      context.resume().catch(fail);
      startMusic();
      const hint = document.getElementById('audio-hint');
      if (hint) hint.hidden = true;
    } catch (reason) { fail(reason); }
  }

  function playEffect(name) {
    if (!effectNames.includes(name) || !activated) return;
    requested[name]++;
    initialize();
    buffers.get(name).then(buffer => {
      const active = voices.get(name);
      const maximum = name === 'shatter' ? 6 : 2;
      if (active.length >= maximum) active.shift().stop();
      const source = context.createBufferSource();
      source.buffer = buffer;
      source.connect(sfxLimiter);
      active.push(source);
      source.onended = () => {
        const index = active.indexOf(source);
        if (index >= 0) active.splice(index, 1);
        source.disconnect();
      };
      source.start();
      played[name]++;
    }).catch(fail);
  }

  function peak(node) {
    if (!node) return 0;
    const data = new Float32Array(node.fftSize);
    node.getFloatTimeDomainData(data);
    return data.reduce((value, sample) => Math.max(value, Math.abs(sample)), 0);
  }

  music.addEventListener('ended', () => {
    if (enabled && activated) {
      music.currentTime = 0;
      startMusic();
    }
  });
  music.addEventListener('error', () => fail(music.error && music.error.message || 'Music could not load.'));
  document.addEventListener('pointerdown', unlock, true);
  document.addEventListener('keydown', unlock, true);
  window.LineGapAudio = Object.freeze({
    startMusic, setMusicEnabled, playEffect,
    // Read-only playback information is useful when verifying browser exports.
    status: () => ({ enabled, activated, context: context && context.state,
      musicPaused: music.paused, musicPosition: music.currentTime,
      musicDuration: Number.isFinite(music.duration) ? music.duration : null,
      musicLoop: music.loop, musicPeak: peak(musicMeter), sfxPeak: peak(sfxMeter), outputPeak: peak(outputMeter),
      requested: { ...requested }, played: { ...played }, error })
  });
})();
