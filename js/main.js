/**
 * SmartMuseum — Main Interactive Scripts
 * Lightweight, zero-dependency vanilla JS
 */

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initScrollSpy();
  initScrollReveal();
  initMockupFallbacks();
});

/**
 * Mobile navigation toggle and link clicks
 */
function initNavigation() {
  const toggleBtn = document.querySelector('.nav-toggle');
  const navLinks = document.querySelector('.nav-links');
  const links = document.querySelectorAll('.nav-link');

  if (!toggleBtn || !navLinks) return;

  toggleBtn.addEventListener('click', () => {
    const isExpanded = toggleBtn.getAttribute('aria-expanded') === 'true';
    toggleBtn.setAttribute('aria-expanded', !isExpanded);
    navLinks.classList.toggle('is-open');
  });

  // Close nav on link click (mobile)
  links.forEach(link => {
    link.addEventListener('click', () => {
      toggleBtn.setAttribute('aria-expanded', 'false');
      navLinks.classList.remove('is-open');
    });
  });

  // Close mobile nav when clicking outside
  document.addEventListener('click', (e) => {
    if (!toggleBtn.contains(e.target) && !navLinks.contains(e.target) && navLinks.classList.contains('is-open')) {
      toggleBtn.setAttribute('aria-expanded', 'false');
      navLinks.classList.remove('is-open');
    }
  });
}

/**
 * Active navigation link highlight via IntersectionObserver
 */
function initScrollSpy() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link');

  if (!sections.length || !navLinks.length) return;

  const observerOptions = {
    root: null,
    rootMargin: '-20% 0px -70% 0px',
    threshold: 0
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id');
        navLinks.forEach(link => {
          if (link.getAttribute('href') === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });
      }
    });
  }, observerOptions);

  sections.forEach(section => observer.observe(section));
}

/**
 * Subtle scroll reveal animations
 */
function initScrollReveal() {
  const revealElements = document.querySelectorAll('.reveal');
  if (!revealElements.length) return;

  // If user prefers reduced motion, show immediately
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    revealElements.forEach(el => el.classList.add('is-visible'));
    return;
  }

  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: '0px 0px -40px 0px'
  });

  revealElements.forEach(el => revealObserver.observe(el));
}

/**
 * Handle screen mockups:
 * - assets/images/screen-exhibit.png: if exists, show phone frame beside tour cards; else silently skip
 */
function initMockupFallbacks() {
  const exhibitContainer = document.getElementById('tour-exhibit-mockup');
  const exhibitImg = document.getElementById('screen-exhibit-img');

  if (exhibitContainer && exhibitImg) {
    const tester = new Image();
    tester.src = 'assets/images/screen-exhibit.png';
    tester.onload = () => {
      exhibitImg.src = tester.src;
      exhibitContainer.style.display = 'block';
      const tourGrid = document.querySelector('.tour-layout-wrapper');
      if (tourGrid) tourGrid.classList.add('has-mockup');
    };
    tester.onerror = () => {
      exhibitContainer.style.display = 'none';
    };
  }
}
