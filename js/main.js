/**
 * SmartMuseum — Main Interactive Scripts
 * Lightweight, zero-dependency vanilla JS
 */

document.addEventListener('DOMContentLoaded', () => {
  initHeroVideo();
  initNavigation();
  initScrollSpy();
  initScrollReveal();
  initTourCarousel();
});

/**
 * Background hero video playback initialization (Muted & Autoplay assurance)
 */
function initHeroVideo() {
  const video = document.querySelector('.hero-video-bg');
  if (!video) return;

  video.muted = true;
  video.defaultMuted = true;
  video.playsInline = true;

  const playPromise = video.play();
  if (playPromise !== undefined) {
    playPromise.catch(() => {
      // Autoplay might be deferred by browser policy until first user interaction
      const resume = () => {
        video.play().catch(() => {});
        window.removeEventListener('touchstart', resume);
        window.removeEventListener('click', resume);
        window.removeEventListener('scroll', resume);
      };
      window.addEventListener('touchstart', resume, { passive: true });
      window.addEventListener('click', resume, { passive: true });
      window.addEventListener('scroll', resume, { passive: true });
    });
  }
}

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
 * Palace Tour Mobile Display Carousel
 * Handles sliding between APK Overview screenshot and individual tour stops
 */
function initTourCarousel() {
  const track = document.getElementById('tour-carousel-track');
  const slides = document.querySelectorAll('.phone-carousel-slide');
  const prevBtn = document.querySelector('.carousel-btn-prev');
  const nextBtn = document.querySelector('.carousel-btn-next');
  const dots = document.querySelectorAll('.carousel-dot');
  const tourCards = document.querySelectorAll('.tour-card');
  const overviewBar = document.querySelector('.tour-overview-bar');
  const phoneMockup = document.querySelector('.phone-mockup');

  if (!track || !slides.length) return;

  let currentIndex = 0;
  const totalSlides = slides.length;
  let autoTimer = null;
  const AUTO_INTERVAL = 5500;

  function updateSlide(index) {
    currentIndex = (index + totalSlides) % totalSlides;
    track.style.transform = `translateX(-${currentIndex * 100}%)`;

    // Update slide classes and aria attributes
    slides.forEach((slide, i) => {
      slide.classList.toggle('is-active', i === currentIndex);
      slide.setAttribute('aria-hidden', i !== currentIndex ? 'true' : 'false');
    });

    // Update dots
    dots.forEach((dot, i) => {
      dot.classList.toggle('is-active', i === currentIndex);
      dot.setAttribute('aria-selected', i === currentIndex ? 'true' : 'false');
    });

    // Update overview bar active state
    if (overviewBar) {
      overviewBar.classList.toggle('is-active', currentIndex === 0);
    }

    // Update tour cards active states (stops 1, 2, 3 correspond to slide index 1, 2, 3)
    tourCards.forEach(card => {
      const stopNum = parseInt(card.getAttribute('data-stop'), 10);
      card.classList.toggle('is-active', stopNum === currentIndex);
    });
  }

  function startAutoPlay() {
    stopAutoPlay();
    autoTimer = setInterval(() => {
      updateSlide(currentIndex + 1);
    }, AUTO_INTERVAL);
  }

  function stopAutoPlay() {
    if (autoTimer) {
      clearInterval(autoTimer);
      autoTimer = null;
    }
  }

  // Prev / Next button listeners
  if (prevBtn) {
    prevBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      stopAutoPlay();
      updateSlide(currentIndex - 1);
    });
  }

  if (nextBtn) {
    nextBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      stopAutoPlay();
      updateSlide(currentIndex + 1);
    });
  }

  // Dots navigation
  dots.forEach(dot => {
    dot.addEventListener('click', (e) => {
      e.stopPropagation();
      stopAutoPlay();
      const target = parseInt(dot.getAttribute('data-slide-target'), 10);
      updateSlide(target);
    });
  });

  // Overview selector button
  if (overviewBar) {
    overviewBar.addEventListener('click', () => {
      stopAutoPlay();
      updateSlide(0);
    });
  }

  // Tour cards click to jump to corresponding stop slide
  tourCards.forEach(card => {
    card.addEventListener('click', () => {
      stopAutoPlay();
      const stopNum = parseInt(card.getAttribute('data-stop'), 10);
      updateSlide(stopNum);
    });

    // Keyboard accessibility: Enter or Space
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        stopAutoPlay();
        const stopNum = parseInt(card.getAttribute('data-stop'), 10);
        updateSlide(stopNum);
      }
    });
  });

  // Touch swipe support for mobile
  let touchStartX = 0;
  let touchStartY = 0;

  track.addEventListener('touchstart', (e) => {
    stopAutoPlay();
    touchStartX = e.changedTouches[0].screenX;
    touchStartY = e.changedTouches[0].screenY;
  }, { passive: true });

  track.addEventListener('touchend', (e) => {
    const touchEndX = e.changedTouches[0].screenX;
    const touchEndY = e.changedTouches[0].screenY;
    const deltaX = touchEndX - touchStartX;
    const deltaY = touchEndY - touchStartY;

    // Horizontal swipe threshold
    if (Math.abs(deltaX) > 40 && Math.abs(deltaX) > Math.abs(deltaY)) {
      if (deltaX < 0) {
        updateSlide(currentIndex + 1);
      } else {
        updateSlide(currentIndex - 1);
      }
    }
  }, { passive: true });

  // Pause on hover
  if (phoneMockup) {
    phoneMockup.addEventListener('mouseenter', stopAutoPlay);
    phoneMockup.addEventListener('mouseleave', startAutoPlay);
  }

  // Initial setup
  updateSlide(0);
  startAutoPlay();
}
