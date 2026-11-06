# Functional Specification Document — Static Site Generator

## 1. Overview

A POSIX `sh`-based static site generator that transforms Markdown content + HTML templates into a clean, `.html`-free URL structure under `public/`. The site is a personal embedded-systems blog for **Ajit Ananthadevan**.

---

## 2. Build Toolchain

| Component | Role |
|---|---|
| `build.sh` | POSIX `sh` script; the sole build orchestrator |
| `pandoc` | Markdown → HTML5 conversion with Pygments syntax highlighting |
| `d2` | Renders inline `d2` code blocks to SVG via the `templates/d2.lua` pandoc filter |
| `awk` / `sed` / `tr` | Frontmatter parsing, line-ending normalization, string manipulation |

**Prerequisites:** `pandoc` must be installed (installable via `apk add pandoc` on Alpine). `d2` must also be installed and on `PATH` (see <https://d2lang.com> for install methods). `build.sh` aborts early with a clear error if `d2` is missing.

---

## 3. Input Directory Structure

```
/
├── build.sh
├── content/
│   ├── _index.md              # Homepage / about content
│   └── posts/                 # Blog posts (Markdown + YAML frontmatter)
├── templates/
│   ├── 404.html               # Copied to /404/
│   ├── _head_extend.html      # Injected before </head> on *every* page
│   ├── d2.lua                 # pandoc Lua filter: renders ```d2 blocks to inline SVG
│   ├── services.html          → /services/
│   └── donate.html            → /donate/
└── static/                    # Blind-copied into public/ (including dotfiles)
    ├── main.css               # Unified stylesheet
    ├── icon/                  # Social & UI icons (SVG)
    ├── img/                   # Images (avatar.jpg, favicons, post images)
    ├── CNAME                  # simplycreate.online
    ├── .nojekyll
    └── googleef627f03eb89068d.html   # Google site verification
```

---

## 4. Output Directory Structure (`public/`)

```
public/
├── index.html                 # Homepage (hero + about content)
├── 404.html                   # Custom 404 page
├── main.css                   # Stylesheet
├── sitemap.xml                # XML sitemap
├── CNAME
├── .nojekyll
├── googleef627f03eb89068d.html
├── icon/                      # (copy of static/icon/)
├── img/                       # (copy of static/img/)
├── posts/
│   ├── index.html             # Blog archive (grouped by category, newest first)
│   └── <slug>/
│       └── index.html         # Individual post page
├── services/
│   └── index.html             → /services/
├── donate/
│   └── index.html             → /donate/
└── tags/
    └── <tag-slug>/
        └── index.html         # Tag-filtered post list
```

All page URLs are clean (no `.html` suffix) using directory-based `index.html`.

---

## 5. Page Types & Behaviours

### 5.1 Homepage (`/`)

- Renders from `content/_index.md` via `pandoc`
- Displays hero section:
  - Avatar: `/img/avatar.jpg`
  - Name: **Ajit Ananthadevan**
  - Subtitle: **Interested in Everything Embedded**
  - Social icons (opening in new window where applicable):

    | Icon | Link | Target |
    |---|---|---|
    | `/icon/github.svg` | `https://github.com/ntn888` | `_blank` |
    | `/icon/mastodon-fill.svg` | `https://hachyderm.io/@ajit_456` | `_blank` (rel="me") |
    | `/icon/email.svg` | `mailto:ajit.ananthadevan@gmail.com` | — |
    | `/icon/hand-heart-fill.svg` | `/donate/` | — |

### 5.2 Post Pages (`/posts/<slug>/`)

- Frontmatter fields parsed: `title`, `date`, `draft`, `category`, `tags`
- Posts with `draft: true` are excluded
- **Windows CRLF line endings** are normalized with `tr -d '\r'`
- Code blocks highlighted via `pandoc --syntax-highlighting=pygments`
- Displays: title, date, category link, tag badges, and rendered body
- Tags with spaces produce hyphenated slugs (e.g. `embedded hobbyist` → `embedded-hobbyist`)

### 5.3 Blog Archive (`/posts/`)

- Lists all non-draft posts, grouped by **category** heading (alphabetically), with posts within each category sorted newest-first
- Clean `<ul>` per category with date + linked title

### 5.4 Tag Pages (`/tags/<tag-slug>/`)

- One page per unique tag, listing all posts carrying that tag
- Tags with spaces are slugified to hyphens for URL path
- Posts listed newest first

### 5.5 Static Template Pages

| Route | Source | Notes |
|---|---|---|
| `/404.html` | `templates/404.html` | Copied as-is (with `_head_extend` injection), placed at root |
| `/services/` | `templates/services.html` | Uses `services-wrapper` class for wider layout (`max-width: 900px`) |
| `/donate/` | `templates/donate.html` | Standard wrapper |

### 5.6 `_head_extend.html` Injection

The content of `templates/_head_extend.html` (a Plausible analytics script tag) is injected before `</head>` on every generated HTML page using `awk`.

### 5.7 D2 Diagrams

D2 diagrams may be authored inline within any Markdown source (post body or `_index.md`) as a fenced code block whose info string is `d2`:

````markdown
```d2
client -> server: request
server -> db: query
```
````

The `templates/d2.lua` pandoc filter intercepts these blocks, invokes the `d2` CLI to render SVG, and replaces the block with an inline `<figure class="d2-diagram"><svg>…</svg></figure>`. Behaviour:

- **Output:** inline SVG, themed with D2's default light theme (`0`) and dark theme (`200`); the SVG carries a `prefers-color-scheme` media query so it adapts to the site's dark mode automatically.
- **Accessibility:** an optional `alt` attribute supplies the SVG's `aria-label` and `<title>` (default `diagram`), e.g. `` ```d2 {alt="Clock tree"} ``.
- **Sizing:** `static/main.css` caps diagram width at the content width and centres it.
- **Failures:** if `d2` cannot render a block, the filter emits the raw source in a `.d2-error` block (rendered with the amber accent border) rather than aborting the entire build.

---

## 6. Unified Stylesheet (`static/main.css`)

- Located at `static/main.css`, copied to `public/main.css`
- Referenced from every page via `<link rel="stylesheet" href="/main.css">`
- Design characteristics:
  - **Font:** Georgia / serif stack (editorial feel)
  - **Colour palette:** Warm off-white background (`#fafaf9`), warm amber accent (`#b45309`), soft text (`#57534e`)
  - **Max content width:** 720px (900px for services page)
  - **Responsive:** Font size and layout adjustments below 600px
  - **Code:** Monospace stack with subtle background, Pygments-compatible
  - **Elements styled:** Headings, links, blockquotes, tables, code blocks, navigation, hero, social icons, tag badges, post archive list, service cards grid, donate page, error page, footer

---

## 7. Sitemap (`public/sitemap.xml`)

- XML sitemap generated at build time
- Includes URLs for:
  - `/` (priority 1.0)
  - `/posts/` (priority 0.8)
  - `/services/` (priority 0.7)
  - `/donate/` (priority 0.5)
  - Each post `/posts/<slug>/` (priority 0.6)
  - Each tag `/tags/<tag-slug>/` (priority 0.4)
- Base domain: `https://simplycreate.online` (from `static/CNAME`)

---

## 8. Static Assets

All files and directories under `static/` (including hidden files such as `.nojekyll`, `CNAME`) are recursively copied into `public/` using `cp -r`.

---

## 9. Build Execution

```sh
sh build.sh
```

No configuration file needed; all paths are hardcoded within the script. The script:
1. Cleans `public/`
2. Verifies `d2` is available, then copies static assets
3. Injects `_head_extend` into template pages
4. Processes each post (parse frontmatter → pandoc conversion with `d2.lua` filter → HTML page)
5. Builds `/posts/` archive grouped by category
6. Builds tag pages
7. Builds homepage from `_index.md`
8. Generates `sitemap.xml`

---

## 10. Edge Cases & Known Behaviours

| Concern | Handling |
|---|---|
| CRLF line endings | `tr -d '\r'` normalises before parsing |
| Tags with spaces | Slugified to hyphens for URL paths (e.g. `embedded hobbyist` → `embedded-hobbyist`) |
| Draft posts | Skipped entirely when `draft: true` |
| Missing `TAGS_TEMP` file | Guarded with `if [ -f ... ]` checks |
| Pandoc deprecated flags | Uses `--syntax-highlighting` (not `--highlight-style`) |
| No posts matching a tag | Tag page still generated with empty list |
| Subshell pipe isolation | Tag metadata stored in separate `.tags` temp file to avoid POSIX `sh` subshell scoping issues |
| `d2` missing from `PATH` | `build.sh` aborts immediately with an install hint |
| Invalid `d2` source | Filter emits a `.d2-error` block with the raw source; build continues |
