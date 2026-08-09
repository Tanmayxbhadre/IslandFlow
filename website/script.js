/**
 * IslandFlow — Production Product Website Script
 * Interactive Product Demo, Audio Waveform, Split Comparison Slider, and FAQ.
 */

const DOWNLOAD_URL = "downloads/IslandFlow-1.0.0.dmg";

document.addEventListener('DOMContentLoaded', () => {
  initDownloadButtons();
  initSimulatedClock();
  initInteractiveDemo();
  initComparisonSlider();
  initHelpAccordion();
  initFAQAccordion();
  initMobileMenu();
  initScrollStory();
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

  function switchMode(newMode) {
    currentMode = newMode;
    
    // Update active button
    modeBtns.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mode === newMode);
    });

    // Update active view inside island
    Object.keys(views).forEach(key => {
      if (views[key]) {
        views[key].classList.toggle('active-view', key === newMode);
      }
    });

    // Expand island when mode changes
    expandIsland();
  }

  function expandIsland() {
    island.classList.remove('collapsed');
    island.classList.add('expanded');
  }

  function collapseIsland() {
    island.classList.remove('expanded');
    island.classList.add('collapsed');
  }

  // Hover triggers over notch and island
  if (notchTrigger) {
    notchTrigger.addEventListener('mouseenter', expandIsland);
  }

  island.addEventListener('mouseenter', expandIsland);
  island.addEventListener('mouseleave', () => {
    // Grace period collapse
    setTimeout(() => {
      if (!island.matches(':hover') && !notchTrigger?.matches(':hover')) {
        collapseIsland();
      }
    }, 1200);
  });

  modeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      switchMode(btn.dataset.mode);
    });
  });

  // Default active view
  switchMode('media');

  // Media Player Scrubber Simulation
  initMediaScrubber();
}

function initMediaScrubber() {
  const btnPlayPause = document.getElementById('btn-playpause');
  const playIcon = document.getElementById('playpause-icon');
  const progressFill = document.getElementById('progress-fill');
  const progressTrack = document.getElementById('progress-track');
  const timeCur = document.getElementById('demo-time-cur');
  const timeRem = document.getElementById('demo-time-rem');

  let isPlaying = true;
  let currentSec = 102; // 1:42
  const totalSec = 224; // 3:44

  function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${String(secs).padStart(2, '0')}`;
  }

  function updateScrubber() {
    if (!isPlaying) return;
    currentSec = (currentSec + 1) % totalSec;
    const pct = (currentSec / totalSec) * 100;
    if (progressFill) progressFill.style.width = `${pct}%`;
    if (timeCur) timeCur.textContent = formatTime(currentSec);
    if (timeRem) timeRem.textContent = `-${formatTime(totalSec - currentSec)}`;
  }

  const timer = setInterval(updateScrubber, 1000);

  if (btnPlayPause) {
    btnPlayPause.addEventListener('click', (e) => {
      e.stopPropagation();
      isPlaying = !isPlaying;
      if (playIcon) {
        if (isPlaying) {
          playIcon.innerHTML = `<rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect>`;
        } else {
          playIcon.innerHTML = `<polygon points="5 3 19 12 5 21 5 3"></polygon>`;
        }
      }
    });
  }

  if (progressTrack) {
    progressTrack.addEventListener('click', (e) => {
      e.stopPropagation();
      const rect = progressTrack.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const pct = Math.max(0, Math.min(1, clickX / rect.width));
      currentSec = Math.floor(pct * totalSec);
      updateScrubber();
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

  // Touch Support
  handle.addEventListener('touchstart', (e) => {
    isDragging = true;
  });

  window.addEventListener('touchmove', (e) => {
    if (!isDragging || !e.touches[0]) return;
    updateSlider(e.touches[0].clientX);
  });

  window.addEventListener('touchend', () => {
    isDragging = false;
  });
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

      // Close all items
      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('open'));

      // Toggle clicked item
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
