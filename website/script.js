const header = document.querySelector('[data-header]');
const nav = document.querySelector('[data-nav]');
const navToggle = document.querySelector('[data-nav-toggle]');

const setScrolledState = () => {
  header.classList.toggle('is-scrolled', window.scrollY > 16);
};

const closeNav = () => {
  document.body.classList.remove('nav-open');
  header.classList.remove('is-open');
  nav.classList.remove('is-open');
  navToggle.setAttribute('aria-expanded', 'false');
};

navToggle.addEventListener('click', () => {
  const isOpen = nav.classList.toggle('is-open');
  document.body.classList.toggle('nav-open', isOpen);
  header.classList.toggle('is-open', isOpen);
  navToggle.setAttribute('aria-expanded', String(isOpen));
});

nav.addEventListener('click', (event) => {
  if (event.target.matches('a')) {
    closeNav();
  }
});

window.addEventListener('scroll', setScrolledState, { passive: true });
window.addEventListener('resize', () => {
  if (window.innerWidth > 900) {
    closeNav();
  }
});

setScrolledState();
