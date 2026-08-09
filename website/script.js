/**
 * IslandFlow — Production Product Website Script
 * Live Audio Synthesizer, Interactive Product Demo, Draggable Sliders, Split Comparison & FAQ.
 */

const DOWNLOAD_URL = "downloads/IslandFlow-1.0.0.dmg";

// Web Audio Synth Engine for Live Demo Playback
let audioCtx = null;
let masterGain = null;
let isAudioPlaying = false;
let currentTrackIndex = 0;
let noteInterval = null;

const DEMO_TRACKS = [
  { title: "Midnight City", artist: "M83 — Hurry Up, We're Dreaming", duration: 244, notes: [261.63, 329.63, 392.00, 523.25] },
  { title: "Somewhere Only We Know", artist: "Gustixa — Chill Beats", duration: 183, notes: [293.66, 369.99, 440.00, 587.33] },
  { title: "Starboy", artist: "The Weeknd — Starboy", duration: 230, notes: [329.63, 392.00, 493.88, 659.25] }
];

document.addEventListener('DOMContentLoaded', () => {
  initDownloadButtons();
  initSimulatedClock();
  initInteractiveDemo();
  initComparisonSlider();
  initHelpAccordion();
  initFAQAccordion();
  initMobileMenu();
  initScrollStory();
  initQuietSection();
});

/* -----------------------------------------------------------------------------
 * Download Button Handler
 * ----------------------------------------------------------------------------- */
function initDownloadButtons() {
  const downloadBtns = document.querySelectorAll('a[download]');
  downloadBtns.forEach(btn => {
    btn.setAttribute('href', DOWNLOAD_URL);
    btn.addEventListener('click', (e) => {
      console.log(`[IslandFlow Website] Download initiated from ${btn.id || 'button'}`);
      const btnText = btn.querySelector('span');
      if (btnText) {
        const orig = btnText.textContent;
        btnText.textContent = "Downloading...";
        setTimeout(() => {
          btnText.textContent = "Download Started!";
          setTimeout(() => { btnText.textContent = orig; }, 3000);
        }, 1200);
      }
    });
  });
}

/* -----------------------------------------------------------------------------
 * Simulated macOS Clock
 * ----------------------------------------------------------------------------- */
function initSimulatedClock() {
  const clockEl = document.getElementById('sim-clock');
  if (!clockEl) return;

  function updateClock() {
    const now = new Date();
    let hours = now.getHours();
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    clockEl.textContent = `${hours}:${minutes} ${ampm}`;
  }

  updateClock();
  setInterval(updateClock, 10000);
}

/* -----------------------------------------------------------------------------
 * Interactive Demo Engine
 * ----------------------------------------------------------------------------- */
function initInteractiveDemo() {
  const island = document.getElementById('demo-island');
  const notchTrigger = document.getElementById('notch-trigger');
  const modeBtns = document.querySelectorAll('.mode-btn');
  const views = {
    media: document.querySelector('.view-media'),
    volume: document.querySelector('.view-volume'),
    brightness: document.querySelector('.view-brightness'),
    battery: document.querySelector('.view-battery'),
    charging: document.querySelector('.view-charging'),
    notification: document.querySelector('.view-notification')
  };

  if (!island) return;

  let currentMode = 'media';
  let hoverTimer = null;

  function switchMode(newMode) {
    currentMode = newMode;
    
    // Update active button state
    modeBtns.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mode === newMode);
    });

    // Update active view inside island
    Object.keys(views).forEach(key => {
      if (views[key]) {
        views[key].classList.toggle('active-view', key === newMode);
      }
    });

    expandIsland();
  }

  function expandIsland() {
    clearTimeout(hoverTimer);
    island.classList.remove('collapsed');
    island.classList.add('expanded');
  }

  function collapseIsland() {
    clearTimeout(hoverTimer);
    hoverTimer = setTimeout(() => {
      if (!island.matches(':hover') && !notchTrigger?.matches(':hover')) {
        island.classList.remove('expanded');
        island.classList.add('collapsed');
      }
    }, 1200);
  }

  if (notchTrigger) {
    notchTrigger.addEventListener('mouseenter', expandIsland);
    notchTrigger.addEventListener('mouseleave', collapseIsland);
  }

  island.addEventListener('mouseenter', expandIsland);
  island.addEventListener('mouseleave', collapseIsland);

  modeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      switchMode(btn.dataset.mode);
    });
  });

  // Default active view
  switchMode('media');

  // Media, Volume, Brightness Controls
  initMediaControls();
  initVolumeSlider();
  initBrightnessSlider();
}

/* -----------------------------------------------------------------------------
 * Web Audio Synthesizer (Plays Real Song Audio in Demo)
 * ----------------------------------------------------------------------------- */
function initWebAudio() {
  if (audioCtx) return;
  const AudioCtx = window.AudioContext || window.webkitAudioContext;
  if (!AudioCtx) return;
  audioCtx = new AudioCtx();
  masterGain = audioCtx.createGain();
  masterGain.gain.value = 0.25; // Default demo volume 25%
  masterGain.connect(audioCtx.destination);
}

function playDemoSong() {
  initWebAudio();
  if (!audioCtx) return;

  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }

  isAudioPlaying = true;
  clearInterval(noteInterval);

  const track = DEMO_TRACKS[currentTrackIndex];
  let noteIdx = 0;

  // Synthesize smooth synth melody loop
  noteInterval = setInterval(() => {
    if (!isAudioPlaying || !audioCtx) return;
    try {
      const osc = audioCtx.createOscillator();
      const noteGain = audioCtx.createGain();

      const freq = track.notes[noteIdx % track.notes.length];
      noteIdx++;

      osc.type = 'sine';
      osc.frequency.value = freq;

      const now = audioCtx.currentTime;
      noteGain.gain.setValueAtTime(0.001, now);
      noteGain.gain.linearRampToValueAtTime(0.12, now + 0.1);
      noteGain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);

      osc.connect(noteGain);
      noteGain.connect(masterGain);

      osc.start(now);
      osc.stop(now + 0.65);
    } catch (e) {
      console.log("[Audio Synth]", e);
    }
  }, 400);
}

function pauseDemoSong() {
  isAudioPlaying = false;
  clearInterval(noteInterval);
  if (audioCtx && audioCtx.state === 'running') {
    audioCtx.suspend();
  }
}

/* -----------------------------------------------------------------------------
 * Media Player Scrubber & Track Switcher
 * ----------------------------------------------------------------------------- */
function initMediaControls() {
  const btnPlayPause = document.getElementById('btn-playpause');
  const btnPrev = document.getElementById('btn-prev');
  const btnNext = document.getElementById('btn-next');
  const playIcon = document.getElementById('playpause-icon');
  const progressFill = document.getElementById('progress-fill');
  const progressTrack = document.getElementById('progress-track');
  const timeCur = document.getElementById('demo-time-cur');
  const timeRem = document.getElementById('demo-time-rem');
  const songTitle = document.querySelector('.song-title');
  const artistName = document.querySelector('.artist-name');

  let currentSec = 102; // 1:42

  function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${String(secs).padStart(2, '0')}`;
  }

  function updateTrackUI() {
    const track = DEMO_TRACKS[currentTrackIndex];
    if (songTitle) songTitle.textContent = track.title;
    if (artistName) artistName.textContent = track.artist;
    currentSec = 0;
    updateProgressUI();
  }

  function updateProgressUI() {
    const track = DEMO_TRACKS[currentTrackIndex];
    const pct = (currentSec / track.duration) * 100;
    if (progressFill) progressFill.style.width = `${pct}%`;
    if (timeCur) timeCur.textContent = formatTime(currentSec);
    if (timeRem) timeRem.textContent = `-${formatTime(track.duration - currentSec)}`;
  }

  setInterval(() => {
    if (!isAudioPlaying) return;
    const track = DEMO_TRACKS[currentTrackIndex];
    currentSec = (currentSec + 1) % track.duration;
    updateProgressUI();
  }, 1000);

  if (btnPlayPause) {
    btnPlayPause.addEventListener('click', (e) => {
      e.stopPropagation();
      if (isAudioPlaying) {
        pauseDemoSong();
        if (playIcon) {
          playIcon.innerHTML = `<polygon points="5 3 19 12 5 21 5 3"></polygon>`;
        }
      } else {
        playDemoSong();
        if (playIcon) {
          playIcon.innerHTML = `<rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect>`;
        }
      }
    });
  }

  if (btnNext) {
    btnNext.addEventListener('click', (e) => {
      e.stopPropagation();
      currentTrackIndex = (currentTrackIndex + 1) % DEMO_TRACKS.length;
      updateTrackUI();
      if (isAudioPlaying) playDemoSong();
    });
  }

  if (btnPrev) {
    btnPrev.addEventListener('click', (e) => {
      e.stopPropagation();
      currentTrackIndex = (currentTrackIndex - 1 + DEMO_TRACKS.length) % DEMO_TRACKS.length;
      updateTrackUI();
      if (isAudioPlaying) playDemoSong();
    });
  }

  if (progressTrack) {
    progressTrack.addEventListener('click', (e) => {
      e.stopPropagation();
      const rect = progressTrack.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const pct = Math.max(0, Math.min(1, clickX / rect.width));
      const track = DEMO_TRACKS[currentTrackIndex];
      currentSec = Math.floor(pct * track.duration);
      updateProgressUI();
    });
  }
}

/* -----------------------------------------------------------------------------
 * Draggable Volume Slider
 * ----------------------------------------------------------------------------- */
function initVolumeSlider() {
  const volTrack = document.querySelector('.view-volume .hud-slider-track');
  const volFill = document.getElementById('vol-fill');
  const volVal = document.getElementById('vol-val');

  if (!volTrack || !volFill || !volVal) return;

  function setVolume(pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    volFill.style.width = `${pct}%`;
    volVal.textContent = `${pct}%`;
    if (masterGain) {
      masterGain.gain.value = (pct / 100) * 0.5;
    }
  }

  let isDragging = false;

  function handleVolMove(clientX) {
    const rect = volTrack.getBoundingClientRect();
    const pct = ((clientX - rect.left) / rect.width) * 100;
    setVolume(pct);
  }

  volTrack.addEventListener('mousedown', (e) => {
    isDragging = true;
    handleVolMove(e.clientX);
  });

  window.addEventListener('mousemove', (e) => {
    if (isDragging) handleVolMove(e.clientX);
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });
}

/* -----------------------------------------------------------------------------
 * Draggable Brightness Slider
 * ----------------------------------------------------------------------------- */
function initBrightnessSlider() {
  const brightTrack = document.querySelector('.view-brightness .hud-slider-track');
  const brightFill = document.getElementById('bright-fill');
  const brightVal = document.getElementById('bright-val');
  const simDesktop = document.querySelector('.sim-desktop-bg');

  if (!brightTrack || !brightFill || !brightVal) return;

  function setBrightness(pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    brightFill.style.width = `${pct}%`;
    brightVal.textContent = `${pct}%`;
    if (simDesktop) {
      const opacity = 0.3 + (pct / 100) * 0.7;
      simDesktop.style.filter = `brightness(${opacity})`;
    }
  }

  let isDragging = false;

  function handleBrightMove(clientX) {
    const rect = brightTrack.getBoundingClientRect();
    const pct = ((clientX - rect.left) / rect.width) * 100;
    setBrightness(pct);
  }

  brightTrack.addEventListener('mousedown', (e) => {
    isDragging = true;
    handleBrightMove(e.clientX);
  });

  window.addEventListener('mousemove', (e) => {
    if (isDragging) handleBrightMove(e.clientX);
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });
}

/* -----------------------------------------------------------------------------
 * Quiet Section Interaction
 * ----------------------------------------------------------------------------- */
function initQuietSection() {
  const quietPill = document.getElementById('quiet-pill');
  if (quietPill) {
    quietPill.addEventListener('click', () => {
      quietPill.style.transform = 'scale(1.3)';
      setTimeout(() => { quietPill.style.transform = 'scale(1)'; }, 300);
    });
  }
}

/* -----------------------------------------------------------------------------
 * Draggable Before / After Comparison Slider
 * ----------------------------------------------------------------------------- */
function initComparisonSlider() {
  const stage = document.getElementById('comparison-stage');
  const afterLayer = document.getElementById('comp-after-layer');
  const handle = document.getElementById('comp-handle');

  if (!stage || !afterLayer || !handle) return;

  let isDragging = false;

  function updateSlider(clientX) {
    const rect = stage.getBoundingClientRect();
    let x = clientX - rect.left;
    x = Math.max(0, Math.min(x, rect.width));
    const pct = (x / rect.width) * 100;

    afterLayer.style.width = `${100 - pct}%`;
    handle.style.left = `${pct}%`;
  }

  handle.addEventListener('mousedown', (e) => {
    isDragging = true;
    e.preventDefault();
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    updateSlider(e.clientX);
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  handle.addEventListener('touchstart', () => { isDragging = true; });
  window.addEventListener('touchmove', (e) => {
    if (!isDragging || !e.touches[0]) return;
    updateSlider(e.touches[0].clientX);
  });
  window.addEventListener('touchend', () => { isDragging = false; });
}

/* -----------------------------------------------------------------------------
 * Gatekeeper Installation Helper Accordion
 * ----------------------------------------------------------------------------- */
function initHelpAccordion() {
  const toggle = document.getElementById('help-toggle');
  const accordion = toggle?.closest('.help-accordion');

  if (toggle && accordion) {
    toggle.addEventListener('click', () => {
      accordion.classList.toggle('open');
    });
  }
}

/* -----------------------------------------------------------------------------
 * FAQ Accordion
 * ----------------------------------------------------------------------------- */
function initFAQAccordion() {
  const faqQuestions = document.querySelectorAll('.faq-question');

  faqQuestions.forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.closest('.faq-item');
      const isOpen = item.classList.contains('open');

      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('open'));

      if (!isOpen) {
        item.classList.add('open');
      }
    });
  });
}

/* -----------------------------------------------------------------------------
 * Mobile Navigation Menu
 * ----------------------------------------------------------------------------- */
function initMobileMenu() {
  const toggleBtn = document.getElementById('mobile-toggle-btn');
  const mobileMenu = document.getElementById('mobile-menu');
  const links = document.querySelectorAll('.mobile-nav-link');

  if (toggleBtn && mobileMenu) {
    toggleBtn.addEventListener('click', () => {
      mobileMenu.classList.toggle('open');
    });

    links.forEach(link => {
      link.addEventListener('click', () => {
        mobileMenu.classList.remove('open');
      });
    });
  }
}

/* -----------------------------------------------------------------------------
 * Scroll-Triggered Story Events
 * ----------------------------------------------------------------------------- */
function initScrollStory() {
  const storyIsland = document.getElementById('story-island-pill');
  const storyTitle = document.getElementById('story-event-title');
  const storyDesc = document.getElementById('story-event-desc');

  if (!storyIsland || !storyTitle || !storyDesc) return;

  const events = [
    { text: "🎵 Playing Midnight City — M83", title: "Media Playback Detected", desc: "Spotify started playing a track. IslandFlow smoothly expands to reveal playback controls." },
    { text: "🔊 Volume 75%", title: "Hardware Volume Adjusted", desc: "You pressed the volume keys. IslandFlow displays a sleek, compact hardware HUD overlay." },
    { text: "⚡ MagSafe Connected (88%)", title: "MagSafe Charger Plugged In", desc: "Power connected. IslandFlow displays instant charging confirmation and battery level." },
    { text: "💬 Sarah: Let's hop on a call!", title: "Incoming Notification", desc: "Notification arrives into your notch without blocking your main workspace." }
  ];

  let stepIndex = 0;

  setInterval(() => {
    stepIndex = (stepIndex + 1) % events.length;
    const evt = events[stepIndex];

    storyIsland.style.opacity = '0';
    setTimeout(() => {
      storyIsland.textContent = evt.text;
      storyTitle.textContent = evt.title;
      storyDesc.textContent = evt.desc;
      storyIsland.style.opacity = '1';
    }, 200);
  }, 4000);
}
