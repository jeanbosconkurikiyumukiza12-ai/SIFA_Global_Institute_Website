/* SIFA public application client. All trust decisions are repeated by the Edge Function. */
(() => {
  const config = window.SIFA_SUPABASE_CONFIG || {};
  const form = document.getElementById('applicationForm');
  if (!form) return;
  const ready = /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(config.url || '') && !!config.anonKey && !String(config.anonKey).includes('YOUR_SUPABASE');
  const notice = (message, type='error') => {
    let box = document.getElementById('studentAuthNotice');
    if (!box) { box = document.createElement('div'); box.id='studentAuthNotice'; box.setAttribute('role','status'); box.style.cssText='margin:0 0 24px;padding:16px 18px;border-radius:12px;border:1px solid #efcaca;background:#fff5f5;color:#8a2d2d;font-weight:600;'; form.parentElement.insertBefore(box, form); }
    box.textContent=message;
    const styles={error:['#fff5f5','#efcaca','#8a2d2d'],warning:['#fff9ed','#ecd59e','#70551a'],success:['#f1faf5','#bfe2cc','#1d6a3d']};
    const c=styles[type]||styles.error; box.style.background=c[0];box.style.borderColor=c[1];box.style.color=c[2];box.scrollIntoView({behavior:'smooth',block:'center'});
  };
  const field = name => { const el=form.elements.namedItem(name); return el && typeof el.value==='string' ? el.value.trim() : ''; };
  const encodeFile = (file,inputName) => new Promise((resolve,reject)=>{
    const reader=new FileReader(); reader.onerror=()=>reject(new Error(`Could not read ${file.name}.`));
    reader.onload=()=>{const result=String(reader.result||'');resolve({name:file.name,type:file.type||'application/octet-stream',field:inputName,base64:result.split(',')[1]||''});};
    reader.readAsDataURL(file);
  });
  form.addEventListener('submit', async event => {
    event.preventDefault(); event.stopImmediatePropagation();
    if (window.SIFA_SETTINGS?.applicationsOpen !== true) { notice('Applications are currently closed. Your information has not been submitted. Please check the SIFA website for the next admissions announcement.','warning'); return; }
    if (!ready) { notice('The application service is not configured. No information has been sent. Please contact sifaglobalinstitute12@gmail.com.'); return; }
    if (!form.reportValidity()) return;
    if (field('course') === 'QuickBooks Practical Training' && !((window.SIFA_SETTINGS?.openPrograms)||[]).includes(field('course'))) { notice('This program is not currently open for applications.'); return; }
    const submitBtn=document.getElementById('submitBtn');
    const oldText=submitBtn?.textContent;
    if(submitBtn){submitBtn.disabled=true;submitBtn.textContent='Submitting securely…';}
    try {
      const values={};
      new FormData(form).forEach((value,key)=>{ if(value instanceof File || ['_subject','name','email','phone','country','course','accuracy','contactConsent','website'].includes(key)) return; values[key]=String(value).trim(); });
      const files=[];let totalFileBytes=0;
      for (const input of Array.from(form.querySelectorAll('input[type="file"]'))) {
        for (const file of Array.from(input.files||[])) {
          if(!file || !file.size) continue;
          if(file.size>5*1024*1024) throw new Error(`${file.name} is larger than 5 MB. Please choose a smaller file.`);
          totalFileBytes+=file.size;if(totalFileBytes>8*1024*1024) throw new Error('All attachments together must be 8 MB or smaller.');
          files.push(await encodeFile(file,input.name));
        }
      }
      if(files.length>8) throw new Error('Please attach no more than eight files.');
      const body={full_name:field('name'),email:field('email'),phone:field('phone'),country:field('country'),program:field('course'),contact_consent:form.elements.namedItem('contactConsent')?.checked===true,accuracy_confirmed:form.elements.namedItem('accuracy')?.checked===true,payload:values,files,website:field('website')};
      const res=await fetch(`${config.url}/functions/v1/public-application`,{method:'POST',headers:{'Content-Type':'application/json','apikey':config.anonKey},body:JSON.stringify(body)});
      const result=await res.json().catch(()=>({}));
      if(!res.ok || !result.ok) throw new Error(result.error||'We could not submit your application. Please try again later.');
      form.style.display='none';
      const card=document.createElement('section'); card.className='application-success-card'; card.setAttribute('aria-live','polite');
      const safeRef=document.createElement('strong'); safeRef.textContent=result.application_ref||'Submitted';
      card.innerHTML='<div class="success-icon" aria-hidden="true">✓</div><span class="eyebrow success-eyebrow">Application received</span><h2>Application submitted successfully</h2><p>Thank you for applying to SIFA Global Institute. Your application has been received for review. Submission does not guarantee admission or a scholarship.</p><div class="success-reference"><span>Application reference</span></div><p class="success-note">Keep this reference for your records. SIFA will contact you using the details you provided.</p><div class="success-actions"><a class="btn btn-primary" href="index.html">Return to Home</a><a class="btn btn-secondary success-secondary" href="courses.html">View Courses</a></div>';
      card.querySelector('.success-reference').appendChild(safeRef); form.parentElement.insertBefore(card,form); card.scrollIntoView({behavior:'smooth',block:'start'});
    } catch(error) { console.error('SIFA application submission failed',error); notice(error?.message||'We could not submit your application. Please try again.'); }
    finally { if(submitBtn){submitBtn.disabled=false;submitBtn.textContent=oldText||'Submit Application';} }
  },true);
})();
