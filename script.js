

// SIFA mobile navigation menu
function initializeSifaMenu() {
  const menu = document.querySelector('header .menu');
  const nav = document.querySelector('header nav ul');

  if (!menu || !nav) return;

  menu.type = 'button';

  function setMenuOpen(isOpen) {
    nav.classList.toggle('open', isOpen);
    menu.setAttribute('aria-expanded', String(isOpen));
    menu.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
    menu.textContent = isOpen ? '✕' : '☰';
  }

  setMenuOpen(false);

  menu.addEventListener('click', function (event) {
    event.preventDefault();
    setMenuOpen(!nav.classList.contains('open'));
  });

  nav.addEventListener('click', function (event) {
    if (event.target.closest('a')) {
      setMenuOpen(false);
    }
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeSifaMenu);
} else {
  initializeSifaMenu();
}


document.querySelectorAll('a[href^="#"]').forEach(a=>{
  a.addEventListener('click',e=>{
    const id=a.getAttribute('href');
    if(id.length>1){
      const el=document.querySelector(id);
      if(el){e.preventDefault();el.scrollIntoView({behavior:'smooth'});nav?.classList.remove('open')}
    }
  })
});

const year=document.querySelector('[data-year]');
if(year) year.textContent=new Date().getFullYear();

const apply=document.querySelector('#applicationForm');

