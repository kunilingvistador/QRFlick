(() => {
  const id = 'G-C0N7TQRY3K';
  const key = 'screenqr-analytics-consent';
  const ru = document.documentElement.lang === 'ru';
  const production = location.hostname === 'kunilingvistador.github.io';
  let enabled = false;
  const read = () => { try { return localStorage.getItem(key); } catch { return null; } };
  const save = value => { try { localStorage.setItem(key, value); } catch {} };
  function start() {
    if (enabled || !production) return;
    enabled = true;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window['ga-disable-' + id] = false;
    gtag('consent', 'default', {analytics_storage: 'granted', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied'});
    gtag('js', new Date());
    gtag('set', {page_location: location.origin + location.pathname, page_referrer: document.referrer ? new URL(document.referrer).origin : ''});
    gtag('config', id, {send_page_view: false, allow_google_signals: false, allow_ad_personalization_signals: false, cookie_prefix: 'screenqr', cookie_path: '/QRFlick/', cookie_expires: 2592000});
    gtag('event', 'page_view', {page_location: location.origin + location.pathname, page_referrer: document.referrer ? new URL(document.referrer).origin : '', page_title: document.title});
    const script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + id;
    document.head.append(script);
  }
  function stop() {
    window['ga-disable-' + id] = true;
    if (window.gtag) gtag('consent', 'update', {analytics_storage: 'denied'});
    enabled = false;
    document.cookie.split(';').forEach(part => {
      const name = part.split('=')[0].trim();
      if (!/^screenqr_ga(?:_|$)/.test(name)) return;
      document.cookie = name + '=; Max-Age=0; Path=/QRFlick/;';
      document.cookie = name + '=; Max-Age=0; Path=/QRFlick/; Domain=kunilingvistador.github.io;';
    });
  }
  const button = document.querySelector('[data-analytics-settings]');
  const panel = document.querySelector('[data-analytics-panel]');
  function show() { panel.hidden = false; panel.querySelector('button').focus(); }
  button?.addEventListener('click', show);
  panel?.querySelectorAll('[data-consent]').forEach(control => control.addEventListener('click', () => {
    const value = control.dataset.consent;
    save(value);
    if (value === 'yes') start(); else stop();
    panel.hidden = true;
    button.focus();
  }));
  if (read() === 'yes') start();
  else if (read() === null && panel) panel.hidden = false;
  document.addEventListener('click', event => {
    const link = event.target.closest('a[href]');
    if (!enabled || !link) return;
    const url = new URL(link.href);
    if (url.hostname === 'github.com' && url.pathname.startsWith('/kunilingvistador/ScreenQR/releases/download/')) {
      const format = url.pathname.endsWith('.dmg') ? 'dmg' : url.pathname.endsWith('.zip') ? 'zip' : null;
      if (format) gtag('event', 'download_click', {file_format: format, language: ru ? 'ru' : 'en', transport_type: 'beacon'});
    }
  });
})();
