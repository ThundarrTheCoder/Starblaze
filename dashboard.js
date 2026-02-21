(function () {
  'use strict';

  var PAGE_SIZE = 25;
  var NAV_LINKS = [
    { href: 'EntraDashboard.html', label: 'Home' },
    { href: 'EntraDashboard.conditional-access.html', label: 'Conditional Access' },
    { href: 'EntraDashboard.users.html', label: 'Users' },
    { href: 'EntraDashboard.groups.html', label: 'Groups' },
    { href: 'EntraDashboard.devices.html', label: 'Devices' },
    { href: 'EntraDashboard.enterprise-apps.html', label: 'Enterprise Apps' },
    { href: 'EntraDashboard.app-registrations.html', label: 'App Registrations' },
    { href: 'EntraDashboard.monitoring-health.html', label: 'Monitoring &amp; Health' },
    { href: 'EntraDashboard.intune-home.html', label: 'Intune' },
    { href: 'EntraDashboard.defender-home.html', label: 'Defender' },
    { href: 'EntraDashboard.pim.html', label: 'PIM' }
  ];

  // ---- Build/upgrade nav ----
  function buildNav() {
    var nav = document.querySelector('.topnav');
    if (!nav) return;

    // Read timestamp from existing .sub or .nav-ts before clearing
    var subEl = document.querySelector('.sub');
    var timestamp = subEl ? subEl.textContent.trim() : '';
    if (subEl) subEl.remove();

    // Check if already upgraded (has .brand)
    if (nav.querySelector('.brand')) {
      markActiveLink(nav);
      return;
    }

    // Clear old pill links
    nav.innerHTML = '';

    // Brand
    var brand = document.createElement('a');
    brand.href = 'EntraDashboard.html';
    brand.className = 'brand';
    brand.innerHTML =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">' +
      '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' +
      'Entra Dashboard';
    nav.appendChild(brand);

    var current = window.location.pathname.split('/').pop() || 'EntraDashboard.html';

    NAV_LINKS.forEach(function (item) {
      var a = document.createElement('a');
      a.href = item.href;
      a.className = 'nav-link';
      a.innerHTML = item.label;
      if (item.href === current) a.classList.add('active');
      nav.appendChild(a);
    });

    // Spacer + timestamp
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

  function markActiveLink(nav) {
    var current = window.location.pathname.split('/').pop() || 'EntraDashboard.html';
    nav.querySelectorAll('.nav-link').forEach(function (a) {
      var href = (a.getAttribute('href') || '').split('/').pop();
      if (href === current) a.classList.add('active');
    });
  }

  // ---- Collapsible sections ----
  function initSections() {
    document.querySelectorAll('.section').forEach(function (section) {
      var h2 = section.querySelector('h2');
      if (!h2) return;
      if (h2.querySelector('.section-chevron')) return; // already done
      var chevron = document.createElement('span');
      chevron.className = 'section-chevron';
      chevron.textContent = '\u25BE';
      h2.appendChild(chevron);
      h2.addEventListener('click', function () {
        section.classList.toggle('collapsed');
      });
    });
  }

  // ---- Table enhancements ----
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

    // --- Card header ---
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
    searchInput.placeholder = 'Filter rows\u2026';

    var exportBtn = document.createElement('button');
    exportBtn.className = 'btn-export';
    exportBtn.innerHTML = '\u2193 CSV';
    exportBtn.title = 'Export visible rows as CSV';

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

    // Pagination container
    var paginationEl = document.createElement('div');
    paginationEl.className = 'pagination';
    tableWrap.after(paginationEl);

    // --- Row color coding ---
    rows.forEach(function (row) {
      if (row.querySelector('.status-red, .status-word-red')) {
        row.classList.add('row-red');
      } else if (row.querySelector('.status-yellow, .status-word-yellow')) {
        row.classList.add('row-yellow');
      } else if (row.querySelector('.status-green, .status-word-green')) {
        row.classList.add('row-green');
      }
    });

    // --- Sort ---
    headers.forEach(function (th, i) {
      th.addEventListener('click', function () {
        if (sortCol === i) {
          sortAsc = !sortAsc;
        } else {
          sortCol = i;
          sortAsc = true;
        }
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
        var na = parseFloat(ta);
        var nb = parseFloat(tb);
        if (!isNaN(na) && !isNaN(nb)) return sortAsc ? na - nb : nb - na;
        return sortAsc ? ta.localeCompare(tb) : tb.localeCompare(ta);
      });
      rows.forEach(function (r) { tbody.appendChild(r); });
    }

    // --- Search ---
    searchInput.addEventListener('input', function () {
      searchVal = searchInput.value.toLowerCase().trim();
      currentPage = 1;
      render();
    });

    // --- Export CSV ---
    exportBtn.addEventListener('click', function () {
      var lines = [];
      var hdrs = headers.map(function (h) {
        return '"' + h.textContent.trim().replace(/"/g, '""') + '"';
      });
      lines.push(hdrs.join(','));
      getVisible().forEach(function (row) {
        var cells = Array.from(row.cells).map(function (cell) {
          return '"' + cell.textContent.trim().replace(/"/g, '""') + '"';
        });
        lines.push(cells.join(','));
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
      return rows.filter(function (r) {
        return r.textContent.toLowerCase().indexOf(searchVal) !== -1;
      });
    }

    function render() {
      var visible = getVisible();
      var total = visible.length;
      var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
      if (currentPage > totalPages) currentPage = 1;
      var start = (currentPage - 1) * PAGE_SIZE;
      var end = start + PAGE_SIZE;

      rows.forEach(function (r) { r.classList.add('hidden'); });
      visible.forEach(function (r, i) {
        if (i >= start && i < end) r.classList.remove('hidden');
      });

      countBadge.textContent = total + ' row' + (total !== 1 ? 's' : '');

      // Pagination
      paginationEl.innerHTML = '';
      if (totalPages <= 1) return;

      var info = document.createElement('span');
      info.className = 'page-info';
      info.textContent = currentPage + ' / ' + totalPages;
      paginationEl.appendChild(info);

      function mkBtn(label, pg, disabled) {
        var btn = document.createElement('button');
        btn.className = 'page-btn' + (pg === currentPage ? ' active' : '');
        btn.textContent = label;
        btn.disabled = !!disabled;
        if (!disabled) {
          btn.addEventListener('click', function () { currentPage = pg; render(); });
        }
        return btn;
      }

      paginationEl.appendChild(mkBtn('\u2039', currentPage - 1, currentPage === 1));

      var prev = null;
      var delta = 2;
      for (var p = 1; p <= totalPages; p++) {
        if (p === 1 || p === totalPages || (p >= currentPage - delta && p <= currentPage + delta)) {
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

  // ---- Init ----
  function init() {
    buildNav();
    initSections();
    document.querySelectorAll('.card').forEach(function (card) {
      enhanceTable(card);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
