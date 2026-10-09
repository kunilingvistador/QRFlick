const trigger=document.querySelector('[data-scan]');
const result=document.querySelector('[data-result]');
if(trigger&&result){trigger.addEventListener('click',()=>{const hidden=result.classList.toggle('hidden');trigger.setAttribute('aria-expanded',String(!hidden));result.setAttribute('aria-hidden',String(hidden));result.inert=hidden;});}
const copy=document.querySelector('[data-copy]');
if(copy){copy.addEventListener('click',async()=>{try{await navigator.clipboard.writeText('https://example.com/screenqr-test');copy.textContent=document.documentElement.lang==='ru'?'Скопировано ✓':'Copied ✓';}catch{copy.textContent=document.documentElement.lang==='ru'?'example.com/screenqr-test':'example.com/screenqr-test';}});}
