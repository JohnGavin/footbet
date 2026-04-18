// =================================================================
// COLLAPSIBLE TABLE OF CONTENTS
// Default: closed. Toggle button to show/hide.
// =================================================================

document.addEventListener('DOMContentLoaded', function() {
  // Find the TOC element
  const toc = document.querySelector('#toc, .pkgdown-toc, aside.col-md-3');

  if (!toc) return; // No TOC on this page

  // Create toggle button
  const toggleBtn = document.createElement('button');
  toggleBtn.className = 'toc-toggle';
  toggleBtn.innerHTML = '☰ TOC';
  toggleBtn.setAttribute('aria-label', 'Toggle table of contents');
  toggleBtn.setAttribute('aria-expanded', 'false');
  document.body.appendChild(toggleBtn);

  // Toggle function
  function toggleTOC() {
    const isVisible = toc.classList.contains('toc-visible');

    if (isVisible) {
      toc.classList.remove('toc-visible');
      toggleBtn.innerHTML = '☰ TOC';
      toggleBtn.setAttribute('aria-expanded', 'false');
    } else {
      toc.classList.add('toc-visible');
      toggleBtn.innerHTML = '✕ Close';
      toggleBtn.setAttribute('aria-expanded', 'true');
    }
  }

  // Click handler
  toggleBtn.addEventListener('click', toggleTOC);

  // Close TOC when clicking outside
  document.addEventListener('click', function(e) {
    if (toc.classList.contains('toc-visible') &&
        !toc.contains(e.target) &&
        !toggleBtn.contains(e.target)) {
      toggleTOC();
    }
  });

  // Close TOC on escape key
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && toc.classList.contains('toc-visible')) {
      toggleTOC();
    }
  });
});

// =================================================================
// DARK MODE DEFAULT
// Default to dark mode if no preference stored
// =================================================================

// Force dark mode always — our plotly plots have black backgrounds
// and our CSS is designed for dark theme only
document.documentElement.setAttribute('data-bs-theme', 'dark');
localStorage.setItem('theme', 'dark');
