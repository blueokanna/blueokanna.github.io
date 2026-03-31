(function () {
    'use strict';

    const GITHUB_USER = 'blueokanna';
    const GITHUB_ORG = 'AstralQuanta';

    /* -------- Init -------- */
    document.addEventListener('DOMContentLoaded', () => {
        initTheme();
        initWeather();
        initHoliday();
        initGreeting();
        initScrollReveal();
        initNavigation();
        initSkillsTabs();
        loadGitHubData();
        initBackToTop();
        init3DTilt();
        initHolidayCanvas();
        /* Hide loading screen after a short delay */
        setTimeout(() => {
            const ls = document.getElementById('loading-screen');
            if (ls) ls.classList.add('hidden');
        }, 1200);
    });

    /* ================================================================
       THEME
       ================================================================ */
    function initTheme() {
        const saved = localStorage.getItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const theme = saved || (prefersDark ? 'dark' : 'light');
        applyTheme(theme);

        const toggle = document.getElementById('theme-toggle');
        if (toggle) toggle.addEventListener('click', () => {
            const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
            applyTheme(next);
            localStorage.setItem('theme', next);
        });

        const mobileSwitch = document.getElementById('mobile-theme-switch');
        if (mobileSwitch) mobileSwitch.addEventListener('change', () => {
            const next = mobileSwitch.selected ? 'dark' : 'light';
            applyTheme(next);
            localStorage.setItem('theme', next);
        });
    }

    function applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        const icon = document.querySelector('#theme-toggle md-icon');
        if (icon) icon.textContent = theme === 'dark' ? 'light_mode' : 'dark_mode';
        const sw = document.getElementById('mobile-theme-switch');
        if (sw) sw.selected = theme === 'dark';
        const meta = document.querySelector('meta[name="theme-color"]');
        if (meta) meta.content = theme === 'dark' ? '#111318' : '#1565C0';
    }

    /* ================================================================
       WEATHER  (Open-Meteo — free, no API key)
       ================================================================ */
    function initWeather() {
        if ('geolocation' in navigator) {
            navigator.geolocation.getCurrentPosition(
                pos => fetchWeather(pos.coords.latitude, pos.coords.longitude),
                () => fallbackGeo(),
                { timeout: 5000 }
            );
        } else {
            fallbackGeo();
        }
    }

    function fallbackGeo() {
        fetch('https://ipapi.co/json/')
            .then(r => r.json())
            .then(d => fetchWeather(d.latitude, d.longitude))
            .catch(() => { });
    }

    function fetchWeather(lat, lon) {
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code&timezone=auto`;
        fetch(url)
            .then(r => r.json())
            .then(d => {
                const temp = Math.round(d.current.temperature_2m);
                const code = d.current.weather_code;
                document.getElementById('weather-temp').textContent = temp + '°C';
                document.getElementById('weather-icon').textContent = weatherIcon(code);
            })
            .catch(() => { });
    }

    function weatherIcon(code) {
        if (code === 0) return '☀️';
        if (code <= 3) return '⛅';
        if (code <= 48) return '🌫️';
        if (code <= 55) return '🌦️';
        if (code <= 65) return '🌧️';
        if (code <= 77) return '🌨️';
        if (code <= 82) return '🌧️';
        return '⛈️';
    }

    /* ================================================================
       HOLIDAY DETECTION
       ================================================================ */
    function initHoliday() {
        const now = new Date();
        const m = now.getMonth() + 1;
        const d = now.getDate();
        let icon = '', name = '';

        /* Fixed-date holidays */
        if (m === 1 && d === 1) { icon = '🎆'; name = 'New Year'; }
        else if (m === 2 && d === 14) { icon = '💕'; name = "Valentine's Day"; }
        else if (m === 3 && d === 8) { icon = '💐'; name = "Women's Day"; }
        else if (m === 4 && d === 1) { icon = '🃏'; name = "April Fools'"; }
        else if (m === 5 && d === 1) { icon = '👷'; name = 'Labour Day'; }
        else if (m === 6 && d === 1) { icon = '🧒'; name = "Children's Day"; }
        else if (m === 10 && d === 1) { icon = '🇨🇳'; name = 'National Day'; }
        else if (m === 10 && d === 31) { icon = '🎃'; name = 'Halloween'; }
        else if (m === 12 && d >= 24 && d <= 25) { icon = '🎄'; name = 'Christmas'; }
        else if (m === 12 && d === 31) { icon = '🥂'; name = "New Year's Eve"; }
        /* Seasonal fallbacks */
        else if (m >= 3 && m <= 5) { icon = '🌸'; name = 'Spring'; }
        else if (m >= 6 && m <= 8) { icon = '☀️'; name = 'Summer'; }
        else if (m >= 9 && m <= 11) { icon = '🍂'; name = 'Autumn'; }
        else { icon = '❄️'; name = 'Winter'; }

        const badge = document.getElementById('holiday-badge');
        if (badge && name) {
            document.getElementById('holiday-icon').textContent = icon;
            document.getElementById('holiday-name').textContent = name;
            badge.style.display = 'flex';
        }
    }

    /* ================================================================
       GREETING (time-of-day aware)
       ================================================================ */
    function initGreeting() {
        const h = new Date().getHours();
        let text, emoji;
        if (h >= 5 && h < 12) { text = 'Good Morning!'; emoji = '🌅'; }
        else if (h >= 12 && h < 17) { text = 'Good Afternoon!'; emoji = '☀️'; }
        else if (h >= 17 && h < 21) { text = 'Good Evening!'; emoji = '🌇'; }
        else { text = 'Good Night!'; emoji = '🌙'; }
        const el = document.getElementById('hero-greeting');
        if (el) {
            el.querySelector('.greeting-wave').textContent = emoji;
            el.querySelector('.greeting-text') ||
                (el.lastChild.textContent = ' ' + text);
            // Update text node
            const nodes = el.childNodes;
            for (let i = 0; i < nodes.length; i++) {
                if (nodes[i].nodeType === 3 && nodes[i].textContent.trim()) {
                    nodes[i].textContent = ' ' + text;
                    break;
                }
            }
        }
    }

    /* ================================================================
       SCROLL REVEAL  (Intersection Observer)
       ================================================================ */
    function initScrollReveal() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('revealed');
                    observer.unobserve(entry.target);
                }
            });
        }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

        document.querySelectorAll('.reveal-up').forEach(el => observer.observe(el));
    }

    /* ================================================================
       NAVIGATION
       ================================================================ */
    function initNavigation() {
        const topBar = document.getElementById('top-bar');

        /* Scroll shadow */
        window.addEventListener('scroll', () => {
            if (topBar) topBar.classList.toggle('scrolled', window.scrollY > 10);
            updateActiveNav();
        }, { passive: true });

        /* Mobile drawer */
        const menuBtn = document.getElementById('menu-toggle');
        const overlay = document.getElementById('mobile-nav-overlay');
        const drawer = document.getElementById('mobile-nav');
        const closeBtn = document.getElementById('mobile-nav-close');

        function openDrawer() { overlay.classList.add('open'); drawer.classList.add('open'); }
        function closeDrawer() { overlay.classList.remove('open'); drawer.classList.remove('open'); }

        if (menuBtn) menuBtn.addEventListener('click', openDrawer);
        if (closeBtn) closeBtn.addEventListener('click', closeDrawer);
        if (overlay) overlay.addEventListener('click', closeDrawer);

        /* Mobile nav items */
        document.querySelectorAll('.mobile-nav-item').forEach(item => {
            item.addEventListener('click', () => {
                const href = item.getAttribute('data-href');
                if (href) document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
                closeDrawer();
            });
        });

        /* Bottom nav */
        document.querySelectorAll('.bottom-nav-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const href = btn.getAttribute('data-href');
                if (href) document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
            });
        });

        /* Smooth scroll for desktop nav links */
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', e => {
                e.preventDefault();
                const target = document.querySelector(link.getAttribute('href'));
                if (target) target.scrollIntoView({ behavior: 'smooth' });
            });
        });
    }

    function updateActiveNav() {
        const sections = ['hero', 'about', 'skills', 'projects', 'contact'];
        let current = 'hero';
        for (const id of sections) {
            const el = document.getElementById(id);
            if (el && el.getBoundingClientRect().top <= 150) current = id;
        }
        /* Desktop nav */
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.toggle('active', link.getAttribute('href') === '#' + current);
        });
        /* Bottom nav */
        document.querySelectorAll('.bottom-nav-btn').forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-href') === '#' + current);
        });
    }

    /* ================================================================
       SKILLS TABS
       ================================================================ */
    function initSkillsTabs() {
        const tabs = document.getElementById('skills-tabs');
        if (!tabs) return;
        const panels = document.querySelectorAll('.skills-panel');
        const panelIds = ['panel-lang', 'panel-fw', 'panel-tools'];

        tabs.addEventListener('change', () => {
            const idx = tabs.activeTabIndex;
            panels.forEach(p => p.classList.remove('active'));
            const panel = document.getElementById(panelIds[idx]);
            if (panel) {
                panel.classList.add('active');
                /* Re-trigger reveal for newly visible cards */
                panel.querySelectorAll('.reveal-up:not(.revealed)').forEach(el => {
                    el.classList.add('revealed');
                });
            }
        });
    }

    /* ================================================================
       GITHUB DATA
       ================================================================ */
    function loadGitHubData() {
        const grid = document.getElementById('projects-grid');

        /* Fetch user info for stats */
        fetch(`https://api.github.com/users/${GITHUB_USER}`)
            .then(r => r.json())
            .then(user => {
                setStatAnimated('stat-repos', user.public_repos || 0);
                setStatAnimated('stat-followers', user.followers || 0);
            })
            .catch(() => { });

        /* Fetch repos */
        Promise.all([
            fetch(`https://api.github.com/users/${GITHUB_USER}/repos?sort=updated&per_page=30`).then(r => r.json()),
            fetch(`https://api.github.com/orgs/${GITHUB_ORG}/repos?sort=updated&per_page=10`).then(r => r.json()).catch(() => [])
        ]).then(([userRepos, orgRepos]) => {
            const allRepos = [...(Array.isArray(userRepos) ? userRepos : []), ...(Array.isArray(orgRepos) ? orgRepos : [])];
            allRepos.sort((a, b) => (b.stargazers_count || 0) - (a.stargazers_count || 0));

            /* Calculate total stars */
            const totalStars = allRepos.reduce((s, r) => s + (r.stargazers_count || 0), 0);
            setStatAnimated('stat-stars', totalStars);

            /* Render project cards */
            if (grid) {
                grid.innerHTML = '';
                const display = allRepos.slice(0, 12);
                display.forEach((repo, i) => {
                    const card = createProjectCard(repo, i);
                    grid.appendChild(card);
                });
            }
        }).catch(() => {
            if (grid) grid.innerHTML = '<p style="grid-column:1/-1;text-align:center;color:var(--md-sys-color-error)">Failed to load projects. Please try again later.</p>';
        });
    }

    function createProjectCard(repo, index) {
        const a = document.createElement('a');
        a.href = repo.html_url;
        a.target = '_blank';
        a.rel = 'noopener';
        a.className = 'project-card tilt-card reveal-up';
        a.style.setProperty('--reveal-delay', (index * 0.05) + 's');
        a.style.animationDelay = (index * 0.06) + 's';

        const langColor = getLanguageColor(repo.language);
        const iconClass = 'pi-' + (index % 8);
        const iconEmoji = getRepoEmoji(repo.language);

        a.innerHTML = `
            <div class="project-card-header">
                <div class="project-card-icon ${iconClass}">${iconEmoji}</div>
                <span class="project-card-title">${escapeHtml(repo.name)}</span>
            </div>
            <p class="project-card-desc">${escapeHtml(repo.description || 'No description provided.')}</p>
            <div class="project-card-footer">
                ${repo.language ? `<span class="project-card-lang"><span class="lang-dot" style="background:${langColor}"></span>${escapeHtml(repo.language)}</span>` : ''}
                <span class="project-card-stat"><md-icon>star</md-icon>${repo.stargazers_count || 0}</span>
                <span class="project-card-stat"><md-icon>call_split</md-icon>${repo.forks_count || 0}</span>
            </div>
        `;

        /* Trigger reveal after being added to DOM */
        requestAnimationFrame(() => {
            requestAnimationFrame(() => a.classList.add('revealed'));
        });

        return a;
    }

    function getRepoEmoji(lang) {
        const map = {
            Java: '☕', Rust: '🦀', Kotlin: '🟣', Python: '🐍', JavaScript: '⚡',
            TypeScript: '💎', Go: '🐹', 'C++': '⚙️', C: '🔧', HTML: '🌐',
            CSS: '🎨', Shell: '🐚', Ruby: '💎', Swift: '🐦', Dart: '🎯'
        };
        return map[lang] || '📦';
    }

    function getLanguageColor(lang) {
        const colors = {
            Java: '#b07219', Rust: '#dea584', Kotlin: '#A97BFF', Python: '#3572A5',
            JavaScript: '#f1e05a', TypeScript: '#3178c6', Go: '#00ADD8', 'C++': '#f34b7d',
            C: '#555555', HTML: '#e34c26', CSS: '#563d7c', Shell: '#89e051',
            Ruby: '#701516', Swift: '#F05138', Dart: '#00B4AB'
        };
        return colors[lang] || '#8b949e';
    }

    function escapeHtml(str) {
        const d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }

    /* -------- Animated stat counter -------- */
    function setStatAnimated(id, target) {
        const el = document.getElementById(id);
        if (!el) return;
        const duration = 1500;
        const start = performance.now();
        function tick(now) {
            const elapsed = now - start;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            el.textContent = Math.round(eased * target);
            if (progress < 1) requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
    }

    /* ================================================================
       BACK TO TOP FAB
       ================================================================ */
    function initBackToTop() {
        const fab = document.getElementById('back-to-top');
        if (!fab) return;
        window.addEventListener('scroll', () => {
            fab.classList.toggle('visible', window.scrollY > 400);
        }, { passive: true });
        fab.addEventListener('click', () => {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }

    /* ================================================================
       3D TILT EFFECT ON CARDS
       ================================================================ */
    function init3DTilt() {
        /* Only apply on non-touch devices for performance */
        if (window.matchMedia('(pointer: fine)').matches) {
            document.querySelectorAll('.tilt-card').forEach(card => {
                card.addEventListener('pointermove', e => {
                    const rect = card.getBoundingClientRect();
                    const x = e.clientX - rect.left;
                    const y = e.clientY - rect.top;
                    const cx = rect.width / 2;
                    const cy = rect.height / 2;
                    const rx = ((y - cy) / cy) * -8;
                    const ry = ((x - cx) / cx) * 8;
                    card.style.transform = `perspective(800px) rotateX(${rx}deg) rotateY(${ry}deg) scale3d(1.03,1.03,1.03)`;
                });
                card.addEventListener('pointerleave', () => {
                    card.style.transform = '';
                });
            });
        }
    }

    /* ================================================================
       HOLIDAY CANVAS  (particle effects)
       ================================================================ */
    let holidayAnim = null;

    function initHolidayCanvas() {
        const canvas = document.getElementById('holiday-canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        let particles = [];
        const m = new Date().getMonth() + 1;

        /* Choose effect based on season/holiday */
        let type = null;
        if (m === 12 || m === 1 || m === 2) type = 'snow';
        else if (m >= 3 && m <= 5) type = 'petals';
        /* Other seasons: no particles (keep it clean) */

        if (!type) { canvas.style.display = 'none'; return; }

        function resize() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }
        resize();
        window.addEventListener('resize', resize);

        /* Create particles */
        const count = Math.min(Math.floor(window.innerWidth / 15), 80);
        for (let i = 0; i < count; i++) {
            particles.push(createParticle(canvas, type));
        }

        function loop() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            particles.forEach(p => {
                updateParticle(p, canvas, type);
                drawParticle(ctx, p, type);
            });
            holidayAnim = requestAnimationFrame(loop);
        }
        loop();
    }

    function createParticle(canvas, type) {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height - canvas.height,
            size: type === 'snow' ? Math.random() * 3 + 1 : Math.random() * 5 + 3,
            speedY: Math.random() * 1.2 + 0.3,
            speedX: Math.random() * 0.6 - 0.3,
            rotation: Math.random() * Math.PI * 2,
            rotSpeed: (Math.random() - 0.5) * 0.02,
            opacity: Math.random() * 0.5 + 0.2,
            wobble: Math.random() * Math.PI * 2
        };
    }

    function updateParticle(p, canvas, type) {
        p.y += p.speedY;
        p.wobble += 0.01;
        p.x += p.speedX + Math.sin(p.wobble) * 0.3;
        p.rotation += p.rotSpeed;
        if (p.y > canvas.height + 10) {
            p.y = -10;
            p.x = Math.random() * canvas.width;
        }
    }

    function drawParticle(ctx, p, type) {
        ctx.save();
        ctx.globalAlpha = p.opacity;
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rotation);
        if (type === 'snow') {
            ctx.beginPath();
            ctx.arc(0, 0, p.size, 0, Math.PI * 2);
            ctx.fillStyle = '#fff';
            ctx.fill();
        } else if (type === 'petals') {
            ctx.beginPath();
            ctx.ellipse(0, 0, p.size, p.size * 0.6, 0, 0, Math.PI * 2);
            ctx.fillStyle = `hsl(${340 + Math.random() * 20}, 80%, ${75 + Math.random() * 15}%)`;
            ctx.fill();
        }
        ctx.restore();
    }
})();
