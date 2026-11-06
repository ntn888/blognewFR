---
title: "Diagrams-as-code"
description: "D2 is a handy tool for developers to generate diagrams using code"
date: 2026-11-07T06:26:00
draft: false
category: ["update"]
tags: ["blogging", "documentation"]
---

Documenting your design or code is an important requisite for any software developer. And diagrams are a necessary part of that. As a coder we code, but reaching for a visual sketch interface would make some whine.

That's where the diagrams-as-code ecosystem come in. Specifically we'll look at [D2](https://github.com/d2lang/d2), or *Declarative Diagramming*. [Mermaid](https://mermaid.js.org/) is another popular one. The idea is simple - you don't sketch from scratch, but describe your diagram in code.

The diagrams on this blog will henceforth be rendered this way. And currently I'm on a journey learning D2 syntax.

## Implementation

Recall that this blog is built using a shell script that invokes *pandoc* to convert my Markdown articles to HTML. Well, now I've added a pandoc filter (written in Lua - thanks deepseek!) that parses D2 codeblocks to SVG inplace.

[Here's](/posts/python-reflex) an example post that implements this.
