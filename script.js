

const menu = document.querySelector('.menu');
const nav = document.querySelector('nav ul');

if (menu && nav) {
  menu.setAttribute('aria-expanded', 'false');

  menu.addEventListener('click', () => {
    const isOpen = nav.classList.toggle('open');
    menu.setAttribute('aria-expanded', String(isOpen));
    menu.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
    menu.textContent = isOpen ? '✕' : '☰';
  });

  nav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      nav.classList.remove('open');
      menu.setAttribute('aria-expanded', 'false');
      menu.setAttribute('aria-label', 'Open menu');
      menu.textContent = '☰';
    });
  });
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

