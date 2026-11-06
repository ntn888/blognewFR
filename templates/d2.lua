--[=[
d2.lua - pandoc Lua filter that renders ```d2 fenced code blocks to inline SVG
using the D2 CLI (https://d2lang.com).

Usage in markdown:

    ```d2
    client -> server: request
    server -> db: query
    ```

An optional alt attribute provides the accessible label:

    ```d2 {alt="Clock tree"}
    ...
    ```

Prerequisite: the `d2` binary must be on PATH. Rendering failures are reported
inline (a .d2-error block) instead of aborting the build.
]=]

local LIGHT_THEME = "0"   -- D2 default (Neutral)
local DARK_THEME = "200"  -- D2 default dark (Dark Mauve)

local function esc_text(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function esc_attr(s)
  return esc_text(s):gsub('"', "&quot;")
end

local function render(code)
  local input = os.tmpname()
  local output = input .. ".svg"
  local fh = io.open(input, "w")
  if not fh then
    return nil, "could not create temporary file"
  end
  fh:write(code)
  fh:close()

  local ok, res = pcall(pandoc.pipe, "d2", {
    "--no-xml-tag",
    "--theme", LIGHT_THEME,
    "--dark-theme", DARK_THEME,
    input, output,
  }, "")

  local svg = nil
  local err = nil
  if ok then
    local rh = io.open(output, "r")
    if rh then
      svg = rh:read("a")
      rh:close()
    else
      err = "d2 produced no output"
    end
  else
    err = res
  end

  os.remove(input)
  os.remove(output)
  return svg, err
end

local function d2_block(cb)
  if not cb.classes:includes("d2") then
    return nil
  end

  local alt = cb.attributes["alt"] or "diagram"
  local svg, err = render(cb.text)

  if not svg then
    return pandoc.Div(
      {
        pandoc.Para({ pandoc.Str("D2 render failed: " .. tostring(err)) }),
        pandoc.CodeBlock(cb.text, { "d2", "failed" }),
      },
      pandoc.Attr("", { "d2-error" })
    )
  end

  -- Make the inline SVG accessible and let CSS cap its width.
  svg = svg:gsub("<svg", function()
    return '<svg role="img" aria-label="' .. esc_attr(alt) .. '"'
  end, 1)
  svg = svg:gsub("(<svg[^>]*>)", function(tag)
    return tag .. "<title>" .. esc_text(alt) .. "</title>"
  end, 1)

  return pandoc.RawBlock("html", '<figure class="d2-diagram">' .. svg .. "</figure>")
end

return {
  { CodeBlock = d2_block },
}
