export async function loadSite(){
  const res = await fetch('/data/site.json'); const data = await res.json();
  const y = document.getElementById('y'); if(y) y.textContent = new Date().getFullYear();
  const em = document.getElementById('emailLink'); if(em){ em.href = 'mailto:'+data.owner.email; em.textContent = data.owner.email; }
  const wa = document.getElementById('waLink'); if(wa){ wa.href = data.owner.whatsapp; }
  const waCTA = document.getElementById('waCTA'); if(waCTA){ waCTA.href = data.owner.whatsapp; }
  const phones = document.getElementById('phones'); if(phones){ phones.textContent = data.owner.phones.join(' · '); }
  const svc = document.getElementById('svcGrid'); if(svc){ svc.innerHTML = data.services.map(s => `<div class="card"><h3>${s.name}</h3><div class="price">From ${s.price}</div><ul class="list">${s.points.map(p=>`<li>${p}</li>`).join('')}</ul></div>`).join(''); }
  const aff = document.getElementById('affGrid'); if(aff){ aff.innerHTML = data.trading.affiliates.map(a => `<div class="card"><h3>${a.name}</h3><p style="color:#86efac;margin:6px 0">${a.perk||''}</p><a class="btn" href="${a.url}" target="_blank" rel="nofollow sponsored noopener">${a.cta||'Sign up'}</a></div>`).join(''); }
}
loadSite();