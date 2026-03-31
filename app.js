/* ================================================================
   Blue's PulseLink Blog — Production JavaScript
   ================================================================ */
;(function () {
  'use strict';

  /* ──────── CONSTANTS ──────── */
  const GH_USER       = 'blueokanna';
  const GH_ORG        = 'AstralQuanta';
  const GH_API        = 'https://api.github.com';
  const WEATHER_API   = 'https://api.open-meteo.com/v1/forecast';
  const GEO_API       = 'https://ipapi.co/json/';
  const WASM_HOOK     = '__pulselink_wasm';

  /* ──────── DOM CACHE ──────── */
  const $ = (s, p) => (p || document).querySelector(s);
  const $$ = (s, p) => [...(p || document).querySelectorAll(s)];

  const dom = {
    loader:         $('#loader'),
    topbar:         $('#topbar'),
    themeBtn:       $('#theme-btn'),
    themeIcon:      $('#theme-icon'),
    menuBtn:        $('#menu-btn'),
    drawer:         $('#drawer'),
    drawerScrim:    $('#drawer-scrim'),
    drawerClose:    $('#drawer-close'),
    drawerToggle:   $('#drawer-theme-toggle'),
    weatherIcon:    $('#weather-icon'),
    weatherTemp:    $('#weather-temp'),
    holidayBadge:   $('#holiday-badge'),
    holidayIcon:    $('#holiday-icon'),
    holidayText:    $('#holiday-text'),
    greetingEmoji:  $('#greeting-emoji'),
    greetingText:   $('#greeting-text'),
    particlesCanvas:$('#particles'),
    fabTop:         $('#fab-top'),
    projectsGrid:   $('#projects-grid'),
    projectsLoading:$('#projects-loading'),
    statRepos:      $('#stat-repos'),
    statStars:      $('#stat-stars'),
    statFollowers:  $('#stat-followers'),
    statYears:      $('#stat-years'),
    tabIndicator:   $('#tab-indicator'),
  };

  /* ──────── THEME ──────── */
  const Theme = {
    KEY: 'pl-theme',
    get() {
      const saved = localStorage.getItem(this.KEY);
      if (saved) return saved;
      return matchMedia('(prefers-color-scheme:dark)').matches ? 'dark' : 'light';
    },
    apply(t) {
      document.documentElement.setAttribute('data-theme', t);
      localStorage.setItem(this.KEY, t);
      dom.themeIcon.textContent = t === 'dark' ? 'light_mode' : 'dark_mode';
      if (dom.drawerToggle) dom.drawerToggle.checked = t === 'dark';
      const metaColor = t === 'dark' ? '#a8c7fa' : '#0b57d0';
      document.querySelectorAll('meta[name="theme-color"]').forEach(m => m.setAttribute('content', metaColor));
    },
    toggle() { this.apply(this.get() === 'dark' ? 'light' : 'dark'); },
    init() {
      this.apply(this.get());
      dom.themeBtn.addEventListener('click', () => this.toggle());
      if (dom.drawerToggle) {
        dom.drawerToggle.addEventListener('change', () => this.toggle());
      }
    },
  };

  /* ──────── DRAWER ──────── */
  const Drawer = {
    open() {
      dom.drawer.classList.add('is-open');
      dom.drawerScrim.classList.add('is-open');
      document.body.style.overflow = 'hidden';
    },
    close() {
      dom.drawer.classList.remove('is-open');
      dom.drawerScrim.classList.remove('is-open');
      document.body.style.overflow = '';
    },
    init() {
      dom.menuBtn.addEventListener('click', () => this.open());
      dom.drawerClose.addEventListener('click', () => this.close());
      dom.drawerScrim.addEventListener('click', () => this.close());
      $$('.drawer__item', dom.drawer).forEach(a =>
        a.addEventListener('click', () => this.close())
      );
    },
  };

  /* ──────── TOPBAR SCROLL ──────── */
  function initTopbarScroll() {
    let ticking = false;
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        dom.topbar.classList.toggle('is-scrolled', window.scrollY > 24);
        ticking = false;
      });
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* ──────── SCROLL SPY ──────── */
  function initScrollSpy() {
    const sections = $$('section[id]');
    const navLinks = $$('.topbar__nav-link[data-section]');
    const drawerLinks = $$('.drawer__item[href]');
    const bottomLinks = $$('.bottom-nav__item[data-section]');

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        const id = entry.target.id;
        [navLinks, drawerLinks, bottomLinks].forEach(group => {
          group.forEach(link => {
            const match = link.dataset.section === id ||
              link.getAttribute('href') === '#' + id;
            link.classList.toggle('is-active', match);
          });
        });
      });
    }, { rootMargin: '-40% 0px -55% 0px', threshold: 0 });

    sections.forEach(s => observer.observe(s));
  }

  /* ──────── REVEAL ON SCROLL ──────── */
  function initReveal() {
    const els = $$('.reveal');
    const observer = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.classList.add('is-visible');
          observer.unobserve(e.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    els.forEach(el => observer.observe(el));
  }

  /* ──────── PROGRESS BAR ANIMATION ──────── */
  function initProgressBars() {
    const bars = $$('.progress__bar');
    const observer = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.classList.add('is-animated');
          observer.unobserve(e.target);
        }
      });
    }, { threshold: 0.3 });
    bars.forEach(b => observer.observe(b));
  }

  /* ──────── TABS ──────── */
  function initTabs() {
    const wrap = $('#skill-tabs-wrap');
    if (!wrap) return;
    const tabs = $$('.tabs__tab', wrap);
    const panels = $$('.tabs__panel', wrap);
    const indicator = dom.tabIndicator;

    function moveIndicator(tab) {
      indicator.style.left = tab.offsetLeft + 'px';
      indicator.style.width = tab.offsetWidth + 'px';
    }

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => { t.classList.remove('is-active'); t.setAttribute('aria-selected', 'false'); });
        panels.forEach(p => p.classList.remove('is-active'));
        tab.classList.add('is-active');
        tab.setAttribute('aria-selected', 'true');
        const panel = $('#' + tab.dataset.panel);
        if (panel) panel.classList.add('is-active');
        moveIndicator(tab);
        // re-trigger progress bars and reveals inside new panel
        if (panel) {
          $$('.progress__bar', panel).forEach(b => b.classList.remove('is-animated'));
          requestAnimationFrame(() => {
            initProgressBars();
            initReveal();
          });
        }
      });
    });

    // Initial indicator position
    requestAnimationFrame(() => {
      const active = tabs.find(t => t.classList.contains('is-active'));
      if (active) moveIndicator(active);
    });
    window.addEventListener('resize', () => {
      const active = tabs.find(t => t.classList.contains('is-active'));
      if (active) moveIndicator(active);
    });
  }

  /* ──────── FAB BACK-TO-TOP ──────── */
  function initFabTop() {
    let ticking = false;
    window.addEventListener('scroll', () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        dom.fabTop.classList.toggle('is-visible', window.scrollY > 500);
        ticking = false;
      });
    }, { passive: true });
    dom.fabTop.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ──────── 3D TILT (pointer: fine) ──────── */
  function initTilt() {
    if (!matchMedia('(pointer:fine)').matches) return;
    $$('.tilt-card').forEach(card => {
      card.addEventListener('mousemove', e => {
        const r = card.getBoundingClientRect();
        const xPct = (e.clientX - r.left) / r.width - 0.5;
        const yPct = (e.clientY - r.top) / r.height - 0.5;
        card.style.transform = `perspective(800px) rotateX(${-yPct * 8}deg) rotateY(${xPct * 8}deg) scale(1.02)`;
        card.style.boxShadow = `${-xPct * 16}px ${-yPct * 16}px 32px rgba(0,0,0,.08)`;
      });
      card.addEventListener('mouseleave', () => {
        card.style.transform = '';
        card.style.boxShadow = '';
      });
    });
  }

  /* ──────── COUNTER ANIMATION ──────── */
  function animateCounter(el, target, duration = 1600) {
    if (!el || isNaN(target)) return;
    const start = performance.now();
    const initial = 0;
    const step = (now) => {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(initial + (target - initial) * eased).toLocaleString();
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  /* ──────── GITHUB DATA ──────── */
  const GitHub = {
    langColors: {
      Java:       '#b07219', Rust:       '#dea584', Kotlin:     '#A97BFF',
      Python:     '#3572A5', JavaScript: '#f1e05a', TypeScript: '#3178c6',
      HTML:       '#e34c26', CSS:        '#563d7c', Go:         '#00ADD8',
      C:          '#555555', 'C++':      '#f34b7d', Shell:      '#89e051',
      Dart:       '#00B4AB', Ruby:       '#701516', Swift:      '#F05138',
      Vue:        '#41b883', Svelte:     '#ff3e00',
    },
    iconForLang(lang) {
      const map = {
        Java: '☕', Rust: '🦀', Kotlin: '🟣', Python: '🐍',
        JavaScript: '⚡', TypeScript: '🔷', Go: '🐹', 'C++': '⚙️',
        C: '⚙️', Dart: '🎯', Ruby: '💎', Swift: '🦅',
        HTML: '🌐', CSS: '🎨', Shell: '🐧',
      };
      return map[lang] || '📦';
    },

    async fetchAll() {
      try {
        const [userRes, reposRes, orgReposRes] = await Promise.all([
          fetch(`${GH_API}/users/${GH_USER}`),
          fetch(`${GH_API}/users/${GH_USER}/repos?per_page=100&sort=stargazers_count&direction=desc`),
          fetch(`${GH_API}/orgs/${GH_ORG}/repos?per_page=100&sort=stargazers_count&direction=desc`).catch(() => null),
        ]);

        if (!userRes.ok || !reposRes.ok) throw new Error('GitHub API error');

        const user = await userRes.json();
        const repos = await reposRes.json();
        let orgRepos = [];
        if (orgReposRes && orgReposRes.ok) {
          orgRepos = await orgReposRes.json();
        }

        const allRepos = [...repos, ...orgRepos];
        const totalStars = allRepos.reduce((s, r) => s + (r.stargazers_count || 0), 0);

        // Stats
        animateCounter(dom.statRepos, user.public_repos || repos.length);
        animateCounter(dom.statStars, totalStars);
        animateCounter(dom.statFollowers, user.followers || 0);

        // Years
        if (user.created_at) {
          const years = Math.max(1, new Date().getFullYear() - new Date(user.created_at).getFullYear());
          dom.statYears.textContent = years + '+';
        }

        // Project cards
        this.renderProjects(allRepos);
      } catch (err) {
        console.warn('[GitHub]', err);
        if (dom.projectsLoading) {
          dom.projectsLoading.innerHTML = '<p style="color:var(--md-on-surface-var)">Could not load projects. <a href="https://github.com/' + GH_USER + '" target="_blank" rel="noopener">Visit GitHub →</a></p>';
        }
      }
    },

    renderProjects(repos) {
      const sorted = repos
        .filter(r => !r.fork && !r.archived)
        .sort((a, b) => (b.stargazers_count || 0) - (a.stargazers_count || 0))
        .slice(0, 9);

      const fragment = document.createDocumentFragment();
      sorted.forEach((repo, i) => {
        const card = document.createElement('a');
        card.href = repo.html_url;
        card.target = '_blank';
        card.rel = 'noopener';
        card.className = 'project-card tilt-card';
        card.style.setProperty('--card-delay', `${i * 0.06}s`);

        const lang = repo.language || 'Code';
        const langColor = this.langColors[lang] || '#888';
        const icon = this.iconForLang(lang);
        const lightColor = this.lighten(langColor, 0.35);

        card.innerHTML = `
          <div class="project-card__top">
            <div class="project-card__icon" style="--pc-c:${langColor};--pc-l:${lightColor}">${icon}</div>
            <h4 class="project-card__name">${this.esc(repo.name)}</h4>
          </div>
          <p class="project-card__desc">${this.esc(repo.description || 'No description provided.')}</p>
          <div class="project-card__meta">
            <span class="project-card__lang">
              <span class="lang-dot" style="background:${langColor}"></span>${this.esc(lang)}
            </span>
            <span class="project-card__stat"><span class="mat-icon">star</span>${repo.stargazers_count || 0}</span>
            <span class="project-card__stat"><span class="mat-icon">call_split</span>${repo.forks_count || 0}</span>
          </div>`;

        fragment.appendChild(card);
      });

      if (dom.projectsLoading) dom.projectsLoading.remove();
      dom.projectsGrid.appendChild(fragment);

      // Re-init tilt for new cards
      requestAnimationFrame(() => initTilt());
    },

    lighten(hex, pct) {
      hex = hex.replace('#', '');
      if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
      const r = parseInt(hex.substring(0, 2), 16);
      const g = parseInt(hex.substring(2, 4), 16);
      const b = parseInt(hex.substring(4, 6), 16);
      const lr = Math.round(r + (255 - r) * pct);
      const lg = Math.round(g + (255 - g) * pct);
      const lb = Math.round(b + (255 - b) * pct);
      return `#${lr.toString(16).padStart(2, '0')}${lg.toString(16).padStart(2, '0')}${lb.toString(16).padStart(2, '0')}`;
    },

    esc(s) {
      const d = document.createElement('div');
      d.textContent = s;
      return d.innerHTML;
    },
  };

  /* ──────── GREETING ──────── */
  function setGreeting() {
    const h = new Date().getHours();
    let text, emoji;
    if (h < 6)       { text = 'Night owl? 🌙';  emoji = '🌙'; }
    else if (h < 12) { text = 'Good Morning!';   emoji = '☀️'; }
    else if (h < 14) { text = 'Good Afternoon!'; emoji = '🌤️'; }
    else if (h < 18) { text = 'Good Afternoon!'; emoji = '🌇'; }
    else if (h < 22) { text = 'Good Evening!';   emoji = '🌆'; }
    else              { text = 'Night owl? 🦉';  emoji = '🌙'; }

    if (dom.greetingText) dom.greetingText.textContent = text;
    if (dom.greetingEmoji) dom.greetingEmoji.textContent = emoji;
  }

  /* ──────── HOLIDAYS ──────── */
  const Holidays = {
    list: [
      { m: 1, d: 1,  icon: '🎆', name: "New Year's Day",   particles: 'fireworks' },
      { m: 2, d: 14, icon: '💝', name: "Valentine's Day",  particles: 'hearts'    },
      { m: 3, d: 8,  icon: '🌷', name: "Women's Day"      },
      { m: 5, d: 1,  icon: '🎊', name: 'Labour Day'       },
      { m: 6, d: 1,  icon: '🎈', name: "Children's Day"   },
      { m: 10,d: 1,  icon: '🇨🇳', name: 'National Day',    particles: 'fireworks' },
      { m: 10,d: 31, icon: '🎃', name: 'Halloween',        particles: 'pumpkins'  },
      { m: 12,d: 25, icon: '🎄', name: 'Christmas',        particles: 'snow'      },
      { m: 12,d: 31, icon: '🎇', name: "New Year's Eve",   particles: 'fireworks' },
    ],
    // Lunar holidays (approximate fixed dates — adjust yearly if needed)
    lunarApprox: [
      { m: 1, d: 29, icon: '🧧', name: 'Spring Festival',  particles: 'fireworks', range: 3 },
      { m: 2, d: 5,  icon: '🏮', name: 'Lantern Festival' },
      { m: 6, d: 22, icon: '🐉', name: 'Dragon Boat Festival' },
      { m: 9, d: 17, icon: '🥮', name: 'Mid-Autumn Festival' },
    ],

    detect() {
      const now = new Date();
      const m = now.getMonth() + 1;
      const d = now.getDate();

      // Check exact holidays
      for (const h of this.list) {
        if (h.m === m && h.d === d) return h;
      }
      // Check lunar (approximate, within range)
      for (const h of this.lunarApprox) {
        const range = h.range || 1;
        const target = new Date(now.getFullYear(), h.m - 1, h.d);
        const diff = Math.abs(now - target) / 86400000;
        if (diff <= range) return h;
      }
      return null;
    },

    apply() {
      const holiday = this.detect();
      if (!holiday) return null;
      dom.holidayIcon.textContent = holiday.icon;
      dom.holidayText.textContent = holiday.name;
      dom.holidayBadge.classList.add('is-visible');
      return holiday;
    },
  };

  /* ──────── WEATHER ──────── */
  const Weather = {
    icons: {
      0:  '☀️', 1:  '🌤️', 2:  '⛅', 3:  '☁️',
      45: '🌫️', 48: '🌫️',
      51: '🌦️', 53: '🌦️', 55: '🌦️',
      61: '🌧️', 63: '🌧️', 65: '🌧️',
      71: '🌨️', 73: '🌨️', 75: '🌨️',
      80: '🌧️', 81: '🌧️', 82: '🌧️',
      95: '⛈️', 96: '⛈️', 99: '⛈️',
    },

    async fetch() {
      try {
        // Try browser geolocation first, fallback to IP-based
        const pos = await this.getPosition();
        const url = `${WEATHER_API}?latitude=${pos.lat}&longitude=${pos.lon}&current_weather=true&timezone=auto`;
        const res = await fetch(url);
        if (!res.ok) throw new Error('Weather API error');
        const data = await res.json();
        const cw = data.current_weather;
        const icon = this.icons[cw.weathercode] || '🌡️';
        dom.weatherIcon.textContent = icon;
        dom.weatherTemp.textContent = Math.round(cw.temperature) + '°C';
      } catch (err) {
        console.warn('[Weather]', err);
      }
    },

    getPosition() {
      return new Promise((resolve) => {
        if ('geolocation' in navigator) {
          navigator.geolocation.getCurrentPosition(
            pos => resolve({ lat: pos.coords.latitude, lon: pos.coords.longitude }),
            () => this.ipFallback().then(resolve),
            { timeout: 4000 }
          );
        } else {
          this.ipFallback().then(resolve);
        }
      });
    },

    async ipFallback() {
      try {
        const res = await fetch(GEO_API);
        const data = await res.json();
        return { lat: data.latitude || 39.9, lon: data.longitude || 116.4 };
      } catch {
        return { lat: 39.9, lon: 116.4 }; // Default to Beijing
      }
    },
  };

  /* ──────── PARTICLES ──────── */
  const Particles = {
    canvas: null,
    ctx: null,
    particles: [],
    running: false,
    mode: 'default', // default | snow | fireworks | hearts | pumpkins

    init(mode = 'default') {
      this.canvas = dom.particlesCanvas;
      if (!this.canvas) return;
      this.ctx = this.canvas.getContext('2d');
      this.mode = mode;
      this.resize();
      window.addEventListener('resize', () => this.resize());
      this.spawn();
      this.running = true;
      this.loop();
    },

    resize() {
      if (!this.canvas) return;
      this.canvas.width = window.innerWidth;
      this.canvas.height = window.innerHeight;
    },

    spawn() {
      const count = this.mode === 'default' ? 40 : 60;
      this.particles = [];
      for (let i = 0; i < count; i++) {
        this.particles.push(this.createParticle());
      }
    },

    createParticle() {
      const w = this.canvas.width;
      const h = this.canvas.height;
      const base = {
        x: Math.random() * w,
        y: Math.random() * h,
        vx: (Math.random() - 0.5) * 0.4,
        vy: Math.random() * 0.3 + 0.1,
        size: Math.random() * 3 + 1,
        opacity: Math.random() * 0.3 + 0.1,
        life: 1,
      };

      switch (this.mode) {
        case 'snow':
          base.size = Math.random() * 4 + 2;
          base.vy = Math.random() * 0.8 + 0.3;
          base.vx = (Math.random() - 0.5) * 0.6;
          base.opacity = Math.random() * 0.5 + 0.3;
          break;
        case 'hearts':
          base.size = Math.random() * 8 + 6;
          base.vy = -(Math.random() * 0.6 + 0.3);
          base.y = h + base.size;
          base.opacity = Math.random() * 0.4 + 0.2;
          break;
        case 'fireworks':
          base.size = Math.random() * 3 + 1;
          base.x = Math.random() * w;
          base.y = h * 0.4 + Math.random() * h * 0.3;
          base.vx = (Math.random() - 0.5) * 2;
          base.vy = (Math.random() - 0.5) * 2;
          base.opacity = Math.random() * 0.7 + 0.3;
          base.life = Math.random() * 0.7 + 0.3;
          base.hue = Math.random() * 360;
          break;
        case 'pumpkins':
          base.size = Math.random() * 10 + 8;
          base.vy = Math.random() * 0.5 + 0.2;
          base.opacity = Math.random() * 0.3 + 0.15;
          break;
      }
      return base;
    },

    loop() {
      if (!this.running) return;
      this.update();
      this.draw();
      requestAnimationFrame(() => this.loop());
    },

    update() {
      const w = this.canvas.width;
      const h = this.canvas.height;
      this.particles.forEach((p, i) => {
        p.x += p.vx;
        p.y += p.vy;

        if (this.mode === 'fireworks') {
          p.life -= 0.004;
          p.opacity *= 0.997;
          if (p.life <= 0) this.particles[i] = this.createParticle();
        } else {
          if (p.y > h + p.size || p.y < -p.size || p.x < -p.size || p.x > w + p.size) {
            this.particles[i] = this.createParticle();
            if (this.mode === 'snow' || this.mode === 'pumpkins') {
              this.particles[i].y = -this.particles[i].size;
            } else if (this.mode === 'hearts') {
              this.particles[i].y = h + this.particles[i].size;
            }
          }
        }
      });
    },

    draw() {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.particles.forEach(p => {
        this.ctx.save();
        this.ctx.globalAlpha = p.opacity;
        switch (this.mode) {
          case 'snow':
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            this.ctx.fillStyle = '#fff';
            this.ctx.fill();
            break;
          case 'hearts':
            this.ctx.font = p.size + 'px serif';
            this.ctx.fillText('❤️', p.x, p.y);
            break;
          case 'fireworks':
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            this.ctx.fillStyle = `hsl(${p.hue},90%,60%)`;
            this.ctx.fill();
            break;
          case 'pumpkins':
            this.ctx.font = p.size + 'px serif';
            this.ctx.fillText('🎃', p.x, p.y);
            break;
          default:
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
            this.ctx.fillStyle = isDark ? 'rgba(168,199,250,0.15)' : 'rgba(11,87,208,0.06)';
            this.ctx.fill();
        }
        this.ctx.restore();
      });
    },

    destroy() {
      this.running = false;
    },
  };

  /* ──────── LOADER ──────── */
  function dismissLoader() {
    dom.loader.classList.add('is-hidden');
    document.body.classList.add('is-loaded');
    setTimeout(() => {
      dom.loader.style.display = 'none';
    }, 700);
  }

  /* ──────── WASM HOOK ──────── */
  window[WASM_HOOK] = {
    ready: false,
    modules: {},
    register(name, mod) {
      this.modules[name] = mod;
      console.log(`[WASM] Module "${name}" registered`);
    },
    call(name, fn, ...args) {
      if (this.modules[name] && typeof this.modules[name][fn] === 'function') {
        return this.modules[name][fn](...args);
      }
      console.warn(`[WASM] ${name}.${fn} not found`);
    },
  };

  /* ──────── BOOT ──────── */
  function boot() {
    Theme.init();
    Drawer.init();
    initTopbarScroll();
    setGreeting();

    const holiday = Holidays.apply();
    Particles.init(holiday?.particles || 'default');

    Weather.fetch();
    GitHub.fetchAll();

    initScrollSpy();
    initReveal();
    initProgressBars();
    initTabs();
    initFabTop();
    initTilt();

    // Dismiss loader after a short delay for fonts/assets
    if (document.readyState === 'complete') {
      setTimeout(dismissLoader, 600);
    } else {
      window.addEventListener('load', () => setTimeout(dismissLoader, 600));
    }

    window[WASM_HOOK].ready = true;
  }

  // Run
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
