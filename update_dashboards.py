#!/usr/bin/env python3
"""Transform all EntraDashboard sub-pages to the new design language."""
import re, os

TEMPLATE_CSS = r"""  <style>
    :root {
      --bg: #06101e;
      --bg2: #0a1929;
      --fg: #e8edf4;
      --muted: #8da2bc;
      --card: rgba(14, 30, 52, 0.7);
      --card-solid: #0e1e34;
      --line: #1a3150;
      --accent: #22d3ee;
      --accent2: #38bdf8;
      --accent-glow: rgba(34, 211, 238, 0.15);
      --green: #22c55e;
      --yellow: #f59e0b;
      --red: #ef4444;
      --glass: rgba(10, 25, 45, 0.75);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, "Segoe UI", system-ui, Roboto, sans-serif;
      color: var(--fg);
      background: var(--bg);
      min-height: 100vh;
      overflow-x: hidden;
    }
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      background:
        radial-gradient(ellipse 80% 60% at 70% 10%, rgba(34, 211, 238, 0.08) 0%, transparent 60%),
        radial-gradient(ellipse 60% 50% at 20% 80%, rgba(56, 189, 248, 0.06) 0%, transparent 60%),
        radial-gradient(ellipse 40% 40% at 50% 50%, rgba(14, 30, 52, 0.5) 0%, transparent 100%);
      z-index: 0;
      pointer-events: none;
    }
    .wrap {
      max-width: 1440px;
      margin: 0 auto;
      padding: 0 24px 40px;
      position: relative;
      z-index: 1;
    }
    /* Sticky Nav */
    .topnav {
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(20px) saturate(1.4);
      -webkit-backdrop-filter: blur(20px) saturate(1.4);
      background: rgba(6, 16, 30, 0.82);
      border-bottom: 1px solid var(--line);
      padding: 10px 24px;
      margin: 0 -24px 28px;
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .topnav .brand {
      font-weight: 700;
      font-size: 15px;
      color: var(--accent);
      margin-right: 12px;
      letter-spacing: 0.5px;
      display: flex;
      align-items: center;
      gap: 8px;
      text-decoration: none;
    }
    .topnav .brand svg { flex-shrink: 0; }
    .topnav a.nav-link {
      display: inline-block;
      text-decoration: none;
      color: var(--muted);
      font-size: 13px;
      font-weight: 500;
      padding: 6px 14px;
      border-radius: 8px;
      transition: all 0.2s;
    }
    .topnav a.nav-link:hover {
      color: var(--fg);
      background: rgba(34, 211, 238, 0.1);
    }
    .topnav a.nav-link.active {
      color: #06101e;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      font-weight: 600;
    }
    /* Header */
    .header { padding: 8px 0 24px; }
    .header h1 {
      font-size: 32px;
      font-weight: 700;
      background: linear-gradient(135deg, #e8edf4 0%, var(--accent) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 4px;
    }
    .header .subtitle {
      color: var(--muted);
      font-size: 14px;
    }
    /* Section Cards */
    .section {
      margin: 0 0 24px;
      border: 1px solid var(--line);
      border-radius: 14px;
      background: var(--card);
      backdrop-filter: blur(12px);
      overflow: hidden;
      animation: fadeUp 0.5s ease-out both;
    }
    .section h2 {
      margin: 0;
      padding: 16px 20px;
      font-size: 16px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 8px;
      border-bottom: 1px solid var(--line);
      color: var(--fg);
      background: none;
    }
    .section h2 svg { width: 18px; height: 18px; color: var(--accent); }
    .cards {
      padding: 0;
    }
    .card {
      border: none;
      border-radius: 0;
      padding: 0;
      background: none;
    }
    .card h3 {
      margin: 0;
      padding: 12px 20px;
      font-size: 14px;
      font-weight: 600;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid rgba(26, 49, 80, 0.3);
      background: rgba(23, 50, 83, 0.2);
    }
    /* Tables */
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }
    th {
      text-align: left;
      padding: 10px 14px;
      background: rgba(23, 50, 83, 0.5);
      color: var(--muted);
      font-weight: 600;
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid var(--line);
      border-right: 1px solid rgba(26, 49, 80, 0.3);
    }
    th:last-child { border-right: none; }
    td {
      padding: 10px 14px;
      border-bottom: 1px solid rgba(26, 49, 80, 0.3);
      vertical-align: top;
      text-align: left;
    }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: rgba(34, 211, 238, 0.03); }
    a { color: var(--accent); text-decoration: none; }
    a:hover { color: #67e8f9; }
    /* Status */
    .status-badge {
      display: inline-block;
      min-width: 72px;
      text-align: center;
      padding: 3px 10px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 600;
    }
    .status-green { background: rgba(34, 197, 94, 0.15); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.3); }
    .status-yellow { background: rgba(245, 158, 11, 0.15); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.3); }
    .status-red { background: rgba(239, 68, 68, 0.15); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.3); }
    .status-gray { background: rgba(107, 114, 128, 0.15); color: #d1d5db; border: 1px solid rgba(107, 114, 128, 0.3); }
    .status-cell {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }
    .status-word {
      font-size: 11px;
      font-weight: 600;
      min-width: 52px;
      text-align: right;
    }
    .status-word-green { color: #22c55e; }
    .status-word-yellow { color: #f59e0b; }
    .status-word-red { color: #ef4444; }
    .status-word-gray { color: #9ca3af; }
    /* Footer */
    .footer {
      margin-top: 8px;
      padding: 20px 0;
      border-top: 1px solid var(--line);
      text-align: center;
      font-size: 12px;
      color: #4a6580;
    }
    .footer a { color: var(--muted); text-decoration: none; }
    .footer a:hover { color: var(--accent); }
    /* Animations */
    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(16px); }
      to { opacity: 1; transform: translateY(0); }
    }
    /* Table container scroll */
    .table-scroll {
      overflow-x: auto;
    }
    .muted { color: var(--muted); }
    .warn {
      margin: 16px 20px;
      padding: 12px 16px;
      border: 1px solid rgba(245, 158, 11, 0.4);
      border-radius: 10px;
      background: rgba(245, 158, 11, 0.1);
      color: #fbbf24;
      font-size: 13px;
    }
  </style>"""

NAV_LINKS = {
    "EntraDashboard.html": "Home",
    "EntraDashboard.conditional-access.html": "Conditional Access",
    "EntraDashboard.users.html": "Users",
    "EntraDashboard.groups.html": "Groups",
    "EntraDashboard.devices.html": "Devices",
    "EntraDashboard.enterprise-apps.html": "Enterprise Apps",
    "EntraDashboard.app-registrations.html": "App Registrations",
    "EntraDashboard.monitoring-health.html": "Monitoring & Health",
    "EntraDashboard.intune-home.html": "Intune",
    "EntraDashboard.defender-home.html": "Defender",
    "EntraDashboard.pim.html": "PIM",
}

SECTION_ICONS = {
    "Conditional Access": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>',
    "Users": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>',
    "Groups": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    "Devices": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>',
    "Enterprise Apps": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>',
    "App Registrations": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>',
    "Monitoring and Health": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>',
    "Intune Home": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M15 2v2"/><path d="M15 20v2"/><path d="M2 15h2"/><path d="M2 9h2"/><path d="M20 15h2"/><path d="M20 9h2"/><path d="M9 2v2"/><path d="M9 20v2"/></svg>',
    "Intune Compliance": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>',
    "Intune Configuration": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
    "Intune Apps": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>',
    "Defender Home": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    "Defender Alerts": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    "Defender Secure Scores": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>',
    "PIM": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    "Enterprise Apps + App Registrations": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>',
}

# Default icon for sections not in the map
DEFAULT_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>'


def build_nav(active_file):
    lines = []
    lines.append('  <nav class="topnav">')
    lines.append('    <a class="brand" href="EntraDashboard.html">')
    lines.append('      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    lines.append('      Entra Dashboard')
    lines.append('    </a>')
    for href, label in NAV_LINKS.items():
        cls = ' active' if href == active_file else ''
        lines.append(f'    <a class="nav-link{cls}" href="{href}">{label}</a>')
    lines.append('  </nav>')
    return '\n'.join(lines)


def extract_generated_date(content):
    m = re.search(r'Generated:\s*([\d\-T: Z]+)', content)
    return m.group(1).strip() if m else '2026-02-13 16:05:52Z'


def extract_title(content):
    m = re.search(r'<title>Entra Dashboard\s*-?\s*(.*?)</title>', content)
    return m.group(1).strip() if m else 'Dashboard'


def extract_sections(content):
    """Extract all <section> blocks from the original file."""
    sections = re.findall(r'<section class="section">(.*?)</section>', content, re.DOTALL)
    return sections


def transform_section(section_html):
    """Transform a single section's content with the new design."""
    # Extract h2 title
    h2_match = re.search(r'<h2>(.*?)</h2>', section_html)
    title = h2_match.group(1) if h2_match else 'Section'

    icon = SECTION_ICONS.get(title, DEFAULT_ICON)

    # Extract card contents
    cards_match = re.search(r'<div class="cards">(.*)', section_html, re.DOTALL)
    cards_content = cards_match.group(1) if cards_match else ''

    # Wrap tables in scrollable container
    cards_content = re.sub(r'<table>', '<div class="table-scroll"><table>', cards_content)
    cards_content = re.sub(r'</table>', '</table></div>', cards_content)

    return f'''    <section class="section">
      <h2>{icon} {title}</h2>
      <div class="cards">
{cards_content}
      </div>
    </section>'''


def transform_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    filename = os.path.basename(filepath)
    title = extract_title(content)
    generated = extract_generated_date(content)
    sections = extract_sections(content)

    nav = build_nav(filename)

    body_sections = '\n'.join(transform_section(s) for s in sections)

    new_html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Entra Dashboard - {title}</title>
{TEMPLATE_CSS}
</head>
<body>

{nav}

  <div class="wrap">
    <header class="header">
      <h1>{title}</h1>
      <div class="subtitle">Generated: {generated}</div>
    </header>

{body_sections}

    <footer class="footer">
      Entra Dashboard &middot; Tenant: Panthro.co &middot; Generated {generated} &middot;
      <a href="EntraDashboard.html">Back to Overview</a>
    </footer>
  </div>
</body>
</html>
'''

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_html)
    print(f'  Updated: {filename}')


def main():
    basedir = os.path.dirname(os.path.abspath(__file__))
    files = [
        'EntraDashboard.conditional-access.html',
        'EntraDashboard.users.html',
        'EntraDashboard.groups.html',
        'EntraDashboard.devices.html',
        'EntraDashboard.enterprise-apps.html',
        'EntraDashboard.app-registrations.html',
        'EntraDashboard.monitoring-health.html',
        'EntraDashboard.intune-home.html',
        'EntraDashboard.defender-home.html',
        'EntraDashboard.pim.html',
        'EntraDashboard.apps.html',
    ]
    print('Transforming dashboard sub-pages...')
    for f in files:
        path = os.path.join(basedir, f)
        if os.path.exists(path):
            transform_file(path)
        else:
            print(f'  Skipped (not found): {f}')
    print('Done!')


if __name__ == '__main__':
    main()
