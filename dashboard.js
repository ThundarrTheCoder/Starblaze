(function () {
  'use strict';

  var PAGE_SIZE = 25;

  var SECTION_ICONS = {
    'conditional access': '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    'users':              '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    'groups':             '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><circle cx="19" cy="7" r="2"/><path d="M23 21v-1a2 2 0 0 0-2-2h-1"/></svg>',
    'devices':            '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>',
    'enterprise apps':    '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg>',
    'app registrations':  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>',
    'monitoring':         '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>',
    'intune':             '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>',
    'defender':           '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg>',
    'pim':                '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>',
    'sections':           '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
    'alerts':             '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    'secure scores':      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>',
    'compliance':         '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="15" x2="15" y2="15"/></svg>',
    'configuration':      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14M4.93 4.93a10 10 0 0 0 0 14.14"/></svg>',
    'apps':               '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="11" height="11" rx="1"/><rect x="13" y="2" width="9" height="9" rx="1"/><rect x="2" y="15" width="9" height="7" rx="1"/><rect x="13" y="13" width="9" height="9" rx="1"/></svg>'
  };

  var MENU_ICONS = {
    'conditional access': '🛡️',
    'users':              '👥',
    'groups':             '🗂️',
    'devices':            '💻',
    'enterprise apps':    '📦',
    'app registrations':  '🔧',
    'monitoring':         '📊',
    'intune':             '📱',
    'defender':           '⚔️',
    'pim':                '🔐'
  };

  var NAV_LINKS = [
    { href: 'EntraDashboard.html',                    label: 'Home' },
    { href: 'EntraDashboard.conditional-access.html', label: 'Cond. Access' },
    { href: 'EntraDashboard.users.html',              label: 'Users' },
    { href: 'EntraDashboard.groups.html',             label: 'Groups' },
    { href: 'EntraDashboard.devices.html',            label: 'Devices' },
    { href: 'EntraDashboard.enterprise-apps.html',    label: 'Ent. Apps' },
    { href: 'EntraDashboard.app-registrations.html',  label: 'App Regs' },
    { href: 'EntraDashboard.monitoring-health.html',  label: 'Monitoring' },
    { href: 'EntraDashboard.intune-home.html',        label: 'Intune' },
    { href: 'EntraDashboard.defender-home.html',      label: 'Defender' },
    { href: 'EntraDashboard.pim.html',                label: 'PIM' }
  ];

  // ==============================
  // Background orbs
  // ==============================
  function injectOrbs() {
    [1, 2, 3].forEach(function (n) {
      var orb = document.createElement('div');
      orb.className = 'bg-orb bg-orb-' + n;
      document.body.insertBefore(orb, document.body.firstChild);
    });
  }

  // ==============================
  // Navigation
  // ==============================
  function buildNav() {
    var nav = document.querySelector('.topnav');
    if (!nav) return;

    var subEl = document.querySelector('.sub');
    var timestamp = subEl ? subEl.textContent.trim() : '';
    if (subEl) subEl.remove();

    if (nav.querySelector('.brand')) {
      markActive(nav);
      return;
    }

    nav.innerHTML = '';
    var current = window.location.pathname.split('/').pop() || 'EntraDashboard.html';

    // Brand
    var brand = document.createElement('a');
    brand.href = 'EntraDashboard.html';
    brand.className = 'brand';
    brand.innerHTML =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' +
      'Entra';
    nav.appendChild(brand);

    var div = document.createElement('div');
    div.className = 'nav-divider';
    nav.appendChild(div);

    NAV_LINKS.forEach(function (item) {
      var a = document.createElement('a');
      a.href = item.href;
      a.className = 'nav-link';
      a.textContent = item.label;
      if (item.href === current) a.classList.add('active');
      nav.appendChild(a);
    });

    var spacer = document.createElement('div');
    spacer.className = 'nav-spacer';
    nav.appendChild(spacer);

    if (timestamp) {
      var ts = document.createElement('span');
      ts.className = 'nav-ts';
      ts.textContent = timestamp;
      nav.appendChild(ts);
    }
  }

  function markActive(nav) {
    var current = window.location.pathname.split('/').pop() || 'EntraDashboard.html';
    nav.querySelectorAll('.nav-link').forEach(function (a) {
      if ((a.getAttribute('href') || '').split('/').pop() === current) a.classList.add('active');
    });
  }

  // ==============================
  // Section icons + collapsible
  // ==============================
  function initSections() {
    document.querySelectorAll('.section').forEach(function (section) {
      var h2 = section.querySelector('h2');
      if (!h2) return;
      if (h2.querySelector('.section-chevron')) return;

      var text = h2.textContent.trim().toLowerCase();
      var icon = null;
      Object.keys(SECTION_ICONS).forEach(function (key) {
        if (text.indexOf(key) !== -1) icon = SECTION_ICONS[key];
      });

      var origText = h2.textContent.trim();
      h2.innerHTML = '';

      if (icon) {
        var iconEl = document.createElement('span');
        iconEl.className = 'section-icon';
        iconEl.innerHTML = icon;
        h2.appendChild(iconEl);
      }

      var titleSpan = document.createElement('span');
      titleSpan.className = 'section-title-text';
      titleSpan.textContent = origText;
      h2.appendChild(titleSpan);

      var chevron = document.createElement('span');
      chevron.className = 'section-chevron';
      chevron.textContent = '\u25BE';
      h2.appendChild(chevron);

      h2.addEventListener('click', function () {
        section.classList.toggle('collapsed');
      });
    });
  }

  // ==============================
  // Home page menu links
  // ==============================
  function enhanceMenuLinks() {
    document.querySelectorAll('.menu-link').forEach(function (link) {
      var text = link.textContent.trim().toLowerCase();
      var emoji = null;
      Object.keys(MENU_ICONS).forEach(function (key) {
        if (text.indexOf(key) !== -1) emoji = MENU_ICONS[key];
      });
      var label = link.textContent.trim();
      link.innerHTML = '';
      if (emoji) {
        var iconDiv = document.createElement('div');
        iconDiv.className = 'menu-link-icon';
        iconDiv.textContent = emoji;
        link.appendChild(iconDiv);
      }
      var labelDiv = document.createElement('div');
      labelDiv.textContent = label;
      link.appendChild(labelDiv);
      var arrow = document.createElement('div');
      arrow.className = 'menu-link-arrow';
      arrow.textContent = '\u2192';
      link.appendChild(arrow);
    });
  }

  // ==============================
  // KPI metric strip
  // ==============================
  function buildKPIs() {
    var pageHeader = document.querySelector('.page-header');
    if (!pageHeader) return;

    // Gather data from tables on page
    var metrics = [];
    document.querySelectorAll('.card').forEach(function (card) {
      var table = card.querySelector('table');
      if (!table) return;
      var h3 = card.querySelector('h3');
      var label = h3 ? h3.textContent.trim() : 'Items';
      var rows = table.querySelectorAll('tbody tr');
      if (rows.length === 0) return;

      // Count by status if applicable
      var reds = card.querySelectorAll('tbody tr .status-red, tbody tr .status-word-red');
      var yellows = card.querySelectorAll('tbody tr .status-yellow, tbody tr .status-word-yellow');
      var greens = card.querySelectorAll('tbody tr .status-green, tbody tr .status-word-green');

      var tone = '';
      if (reds.length > 0) tone = 'kpi-red';
      else if (yellows.length > 0) tone = 'kpi-yellow';
      else if (greens.length > 0) tone = 'kpi-green';

      // Shorten long labels
      var shortLabel = label.replace(/\s*\(.*?\)/g, '').trim();
      if (shortLabel.length > 22) shortLabel = shortLabel.substring(0, 20) + '\u2026';

      metrics.push({ value: rows.length, label: shortLabel, tone: tone });
    });

    if (metrics.length === 0) return;

    // Cap at 8 KPIs
    if (metrics.length > 8) metrics = metrics.slice(0, 8);

    var grid = document.createElement('div');
    grid.className = 'kpi-grid';

    metrics.forEach(function (m, i) {
      var card = document.createElement('div');
      card.className = 'kpi-card' + (m.tone ? ' ' + m.tone : '');
      card.style.animationDelay = (i * 0.06) + 's';

      var val = document.createElement('div');
      val.className = 'kpi-value';
      val.textContent = '0';

      var lbl = document.createElement('div');
      lbl.className = 'kpi-label';
      lbl.textContent = m.label;

      card.appendChild(val);
      card.appendChild(lbl);
      grid.appendChild(card);

      // Count-up animation
      animateCount(val, m.value, i * 80);
    });

    pageHeader.after(grid);
  }

  function animateCount(el, target, delay) {
    var start = null;
    var duration = 900;
    setTimeout(function () {
      function step(timestamp) {
        if (!start) start = timestamp;
        var elapsed = timestamp - start;
        var progress = Math.min(elapsed / duration, 1);
        // Ease out cubic
        var ease = 1 - Math.pow(1 - progress, 3);
        el.textContent = Math.round(ease * target).toLocaleString();
        if (progress < 1) requestAnimationFrame(step);
        else el.textContent = target.toLocaleString();
      }
      requestAnimationFrame(step);
    }, delay);
  }

  // ==============================
  // Table enhancement
  // ==============================
  function enhanceTable(card) {
    var table = card.querySelector('table');
    if (!table) return;

    var h3 = card.querySelector('h3');
    var h3Text = h3 ? h3.textContent.trim() : '';
    if (h3) h3.remove();

    var tbody = table.querySelector('tbody');
    var rows = Array.from(tbody ? tbody.querySelectorAll('tr') : []);
    var headers = Array.from(table.querySelectorAll('thead th'));

    var sortCol = -1;
    var sortAsc = true;
    var searchVal = '';
    var currentPage = 1;

    // Card header
    var cardHeader = document.createElement('div');
    cardHeader.className = 'card-header';

    var titleDiv = document.createElement('div');
    titleDiv.className = 'card-title';
    titleDiv.textContent = h3Text;

    var countBadge = document.createElement('span');
    countBadge.className = 'row-count';
    titleDiv.appendChild(countBadge);

    var tools = document.createElement('div');
    tools.className = 'card-tools';

    var searchInput = document.createElement('input');
    searchInput.type = 'search';
    searchInput.className = 'search-input';
    searchInput.placeholder = 'Filter\u2026';

    var exportBtn = document.createElement('button');
    exportBtn.className = 'btn-export';
    exportBtn.innerHTML = '\u2193&nbsp;CSV';

    tools.appendChild(searchInput);
    tools.appendChild(exportBtn);
    cardHeader.appendChild(titleDiv);
    cardHeader.appendChild(tools);
    card.insertBefore(cardHeader, card.firstChild);

    // Wrap table
    var tableWrap = document.createElement('div');
    tableWrap.className = 'table-wrap';
    table.parentNode.insertBefore(tableWrap, table);
    tableWrap.appendChild(table);

    // Pagination
    var paginationEl = document.createElement('div');
    paginationEl.className = 'pagination';
    tableWrap.after(paginationEl);

    // Row color-coding
    rows.forEach(function (row) {
      if (row.querySelector('.status-red, .status-word-red'))        row.classList.add('row-red');
      else if (row.querySelector('.status-yellow, .status-word-yellow')) row.classList.add('row-yellow');
      else if (row.querySelector('.status-green, .status-word-green'))   row.classList.add('row-green');
    });

    // Sort
    headers.forEach(function (th, i) {
      th.addEventListener('click', function () {
        sortCol === i ? (sortAsc = !sortAsc) : (sortCol = i, sortAsc = true);
        headers.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
        th.classList.add(sortAsc ? 'sort-asc' : 'sort-desc');
        doSort();
        currentPage = 1;
        render();
      });
    });

    function doSort() {
      if (sortCol < 0 || !tbody) return;
      rows.sort(function (a, b) {
        var ta = (a.cells[sortCol] ? a.cells[sortCol].textContent : '').trim().toLowerCase();
        var tb = (b.cells[sortCol] ? b.cells[sortCol].textContent : '').trim().toLowerCase();
        var na = parseFloat(ta), nb = parseFloat(tb);
        if (!isNaN(na) && !isNaN(nb)) return sortAsc ? na - nb : nb - na;
        return sortAsc ? ta.localeCompare(tb) : tb.localeCompare(ta);
      });
      rows.forEach(function (r) { tbody.appendChild(r); });
    }

    // Search
    searchInput.addEventListener('input', function () {
      searchVal = searchInput.value.toLowerCase().trim();
      currentPage = 1;
      render();
    });

    // CSV export
    exportBtn.addEventListener('click', function () {
      var lines = [headers.map(function (h) { return '"' + h.textContent.trim().replace(/"/g, '""') + '"'; }).join(',')];
      getVisible().forEach(function (row) {
        lines.push(Array.from(row.cells).map(function (c) { return '"' + c.textContent.trim().replace(/"/g, '""') + '"'; }).join(','));
      });
      var blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = (h3Text || 'export').replace(/[^a-z0-9]+/gi, '_').toLowerCase() + '.csv';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });

    function getVisible() {
      if (!searchVal) return rows.slice();
      return rows.filter(function (r) { return r.textContent.toLowerCase().indexOf(searchVal) !== -1; });
    }

    function render() {
      var visible = getVisible();
      var total = visible.length;
      var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
      if (currentPage > totalPages) currentPage = 1;
      var start = (currentPage - 1) * PAGE_SIZE;
      var end = start + PAGE_SIZE;

      rows.forEach(function (r) { r.classList.add('hidden'); });
      visible.forEach(function (r, i) { if (i >= start && i < end) r.classList.remove('hidden'); });

      countBadge.textContent = total.toLocaleString() + (total !== 1 ? ' rows' : ' row');

      // Pagination
      paginationEl.innerHTML = '';
      if (totalPages <= 1) return;

      function mkBtn(label, pg, disabled) {
        var btn = document.createElement('button');
        btn.className = 'page-btn' + (pg === currentPage ? ' active' : '');
        btn.innerHTML = label;
        btn.disabled = !!disabled;
        if (!disabled) btn.addEventListener('click', function () { currentPage = pg; render(); });
        return btn;
      }

      var info = document.createElement('span');
      info.className = 'page-info';
      info.textContent = currentPage + '\u2009/\u2009' + totalPages;
      paginationEl.appendChild(info);
      paginationEl.appendChild(mkBtn('\u2039', currentPage - 1, currentPage === 1));

      var prev = null;
      for (var p = 1; p <= totalPages; p++) {
        if (p === 1 || p === totalPages || (p >= currentPage - 2 && p <= currentPage + 2)) {
          if (prev !== null && p - prev > 1) {
            var dots = document.createElement('span');
            dots.className = 'page-ellipsis';
            dots.textContent = '\u2026';
            paginationEl.appendChild(dots);
          }
          paginationEl.appendChild(mkBtn(p, p, false));
          prev = p;
        }
      }
      paginationEl.appendChild(mkBtn('\u203a', currentPage + 1, currentPage === totalPages));
    }

    render();
  }

  // ==============================
  // Init
  // ==============================
  function init() {
    injectOrbs();
    buildNav();
    initSections();
    enhanceMenuLinks();
    document.querySelectorAll('.card').forEach(enhanceTable);
    buildKPIs();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
