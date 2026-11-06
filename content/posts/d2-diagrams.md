---
title: "Diagrams-as-code"
description: "How this blog renders inline D2 diagrams at build time with a pandoc Lua filter"
date: 2026-11-07T06:26:00
draft: false
category: ["update"]
tags: ["blogging", "documentation", "d2", "diagrams"]
---

Documenting your design or code is an important requisite for any software developer, and diagrams are a necessary part of that. As coders we code, but being forced to reach for a visual sketch tool makes many of us whine.

That's where the diagrams-as-code ecosystem comes in. [D2](https://github.com/d2lang/d2), or *Declarative Diagramming*, is one such tool; [Mermaid](https://mermaid.js.org/) is another popular one. The idea is simple: you don't sketch from scratch, you describe the diagram in code.

The diagrams on this blog are now rendered this way. This post is about how I wired D2 into the build, the design choice behind it, and a couple of gotchas I hit along the way.

## Implementation

This blog is built by a POSIX `sh` script that pipes Markdown through [pandoc](https://pandoc.org/) to produce HTML. Pandoc is excellent at Markdown, but it has no idea what a D2 diagram is: a fenced block tagged `d2` is just another code block, syntax-highlighted and left as-is. The goal, then, was to turn those code blocks into real diagrams at build time.

### Two ways to do it

Before writing any code I considered two approaches:

- **Pre-render out of band.** Keep `.d2` sources somewhere, render them to SVG or PNG by hand, drop them into `static/img/`, and reference them from articles with ordinary image tags. No build changes at all.
- **Render inline at build time.** Author the D2 directly inside the article as a fenced block and let the build turn it into a diagram.

The first option is simpler, but the diagram source then lives apart from the prose it belongs to. There's a manual step that's easy to forget, and the two drift over time. The whole point of diagrams-as-code is that the diagram *is* text, versioned next to the article. So I went with the second approach: **the D2 source lives in the Markdown, and the build renders it.**

The natural place to hook in is a **pandoc filter**. Pandoc ships with a Lua interpreter, so a filter needs no additional language runtime — and the only new dependency is the `d2` binary itself.

### The filter

The filter lives at `templates/d2.lua` — written in Lua (thanks, deepseek!). Its core is a `CodeBlock` handler that only touches blocks whose class is `d2`:

```lua
local function d2_block(cb)
  if not cb.classes:includes("d2") then
    return nil
  end
  ...
end
```

For each such block it writes the source to a temporary file, shells out to the `d2` CLI, and reads the SVG back:

```lua
local ok, res = pcall(pandoc.pipe, "d2", {
  "--no-xml-tag",
  "--theme", LIGHT_THEME,
  "--dark-theme", DARK_THEME,
  input, output,
}, "")
```

A few deliberate choices in there:

- **`--no-xml-tag`** strips the `<?xml ... ?>` prolog D2 normally prepends. The SVG is inlined straight into the HTML `<body>`, where an XML declaration doesn't belong.
- **`--theme 0`** and **`--dark-theme 200`** pin D2's default light and dark themes. Because a dark theme is supplied, D2 embeds a `prefers-color-scheme` media query in the SVG, so the diagram follows the reader's light/dark preference the same way the rest of the site does.
- **`pcall`** wraps the call so that one broken diagram can't take down the whole build.

The block is then replaced with an inline `<figure>`:

```lua
return pandoc.RawBlock("html", '<figure class="d2-diagram">' .. svg .. "</figure>")
```

The SVG is also annotated with `role="img"`, an `aria-label`, and a `<title>` taken from an optional `alt` attribute, so the diagram is at least nominally accessible.

### Wiring it into the build

`build.sh` gained three small things: a `LUA_FILTER` variable pointing at the filter, a preflight check that `d2` is on `PATH`, and a `--lua-filter` flag on both pandoc invocations — one for post bodies and one for the homepage:

```sh
html_body=$(echo "$body" | pandoc --from markdown --to html5 \
  --syntax-highlighting=pygments --lua-filter="$LUA_FILTER")
```

A little CSS keeps the diagrams in check: max-width, auto height, and centring, plus a style for the error fallback.

### The whole pipeline

Which, drawn as a diagram, looks like this:

```d2
author -> markdown: writes
markdown -> pandoc: "post body"
pandoc -> d2: "fenced d2 block"
d2 -> pandoc: SVG
pandoc -> html: "public/*/index.html"
```

That diagram is itself a fenced `d2` block in this article's Markdown, rendered by the very filter it describes.

## Writing a diagram

Using it is just a fenced code block tagged `d2`:

````markdown
```d2
client -> server: request
server -> db: query
```
````

Optionally you can attach an `alt` label:

````markdown
```d2 {alt="Request flow"}
client -> server: request
```
````

The `alt` text becomes the SVG's accessible label. You can see it in the wild in [the Reflex post](/posts/python-reflex).

## Gotchas

### `--format svg` isn't a thing

When I first wrote the filter I passed `--format svg`, assuming D2 would take an explicit output format. It didn't, and the build failed with a spectacularly unhelpful message:

```
D2 render failed: Error running d2 (error code 1): <no output>
```

The diagram was fine. D2 has no `--format` flag — the output format is determined by the **output filename extension** (`.svg`, in our case), or by `--stdout-format` when writing to stdout. The `svg` value wasn't the problem; the flag was.

The `<no output>` part is a second trap. `pandoc.pipe` reports a failed command's **stderr**, but D2 prints usage errors to **stdout**, which pandoc discards when the command exits non-zero. So any D2 invocation error surfaces as a blank `<no output>` until you know to look. Dropping `--format` and letting the `.svg` extension do the work was the whole fix.

### Limitations

A couple of things I haven't solved yet:

- **No caching.** `d2` runs fresh for every diagram on every build, because the output directory is wiped each time. Fine for a handful of diagrams; it should eventually be cached by content hash.
- **Duplicate SVG IDs.** D2 emits `id` attributes inside the SVG, so two *identical* diagrams on one page would collide. D2 has a `--salt` flag for exactly this; I just don't set it yet.

## Wrapping up

D2 has turned out to be a pleasant fit for a text-based, shell-driven workflow: the diagram is just more Markdown, the build takes care of the rest, and the output adapts to light and dark mode for free. If you're on a static site and want diagrams without leaving your editor, a pandoc filter like this is a small, self-contained way to get there.
