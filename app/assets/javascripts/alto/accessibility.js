// Accessibility enhancements for Alto

// Mobile menu toggle with proper ARIA states
function toggleMobileSidebar() {
  const sidebar = document.getElementById('mobile-sidebar');
  const triggers = document.querySelectorAll('[aria-controls="mobile-sidebar"]');

  if (sidebar) {
    const isOpen = sidebar.classList.contains('open') || sidebar.style.display !== 'none';
    const newState = !isOpen;

    // Update ARIA states on all menu toggle buttons
    triggers.forEach(trigger => {
      trigger.setAttribute('aria-expanded', newState.toString());
      trigger.setAttribute('aria-label', newState ? 'Close navigation menu' : 'Open navigation menu');
    });

    // Toggle sidebar visibility (assuming your existing toggle logic)
    if (window.toggleSidebar) {
      window.toggleSidebar();
    }
  }
}

// Enhanced focus management for skip links
document.addEventListener('DOMContentLoaded', function() {
  const skipLink = document.querySelector('a[href="#main-content"]');

  if (skipLink) {
    skipLink.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.getElementById('main-content');

      if (target) {
        // Set focus to the main content
        target.setAttribute('tabindex', '-1');
        target.focus();

        // Remove tabindex after focus (so it doesn't interfere with normal tab order)
        target.addEventListener('blur', function() {
          target.removeAttribute('tabindex');
        }, { once: true });

        // Scroll to the target
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  }
});

// Announce dynamic content changes to screen readers
function announceToScreenReader(message, priority = 'polite') {
  const announcement = document.createElement('div');
  announcement.setAttribute('aria-live', priority);
  announcement.setAttribute('aria-atomic', 'true');
  announcement.className = 'sr-only';
  announcement.textContent = message;

  document.body.appendChild(announcement);

  // Remove the announcement after a brief delay
  setTimeout(() => {
    document.body.removeChild(announcement);
  }, 1000);
}

// Export functions for global use
window.toggleMobileSidebar = toggleMobileSidebar;
window.announceToScreenReader = announceToScreenReader;
