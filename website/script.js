/**
 * IslandFlow — Production Download Website Scripts
 */

document.addEventListener('DOMContentLoaded', () => {
  // Direct download button event tracking / verification
  const downloadBtns = document.querySelectorAll('a[download]');
  
  downloadBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      console.log(`[IslandFlow] Download initiated: ${btn.getAttribute('href')}`);
    });
  });

  // Smooth scroll for internal navigation links
  const navLinks = document.querySelectorAll('a[href^="#"]');
  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      const targetId = link.getAttribute('href');
      if (targetId === '#') return;
      
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        e.preventDefault();
        const headerOffset = 80;
        const elementPosition = targetElement.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
      }
    });
  });
});
