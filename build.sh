#!/bin/sh
set -e

PUB="public"
CONTENT="content"
POSTS="${CONTENT}/posts"
TEMPLATES="templates"
STATIC="static"

TITLE_SITE="Ajit Ananthadevan"
SLOGAN="Interested in Everything Embedded"
AUTHOR="Ajit Ananthadevan"

rm -rf "$PUB"
mkdir -p "$PUB"

cp -r "$STATIC"/. "$PUB/"

echo "==> Cleaning output directory..."
echo "==> Copying static assets..."

# ---------- helpers ----------
read HEAD_EXTEND < "$TEMPLATES/_head_extend.html"

page_header() {
  cat <<PHEAD
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${1}</title>
    ${2}
    <link rel="stylesheet" href="/main.css">
    <link rel="icon" type="image/png" sizes="32x32" href="/img/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/img/favicon-16x16.png">
    <link rel="apple-touch-icon" href="/img/apple-touch-icon.png">
    ${HEAD_EXTEND}
</head>
<body>
PHEAD
}

page_nav() {
  cat <<PNAV
    <header>
        <nav>
            <a href="/">home</a><span class="nav-sep">&#183;</span><a href="/posts/">posts</a><span class="nav-sep">&#183;</span><a href="/services/">services</a>
        </nav>
    </header>
PNAV
}

page_footer() {
  cat <<PFOOT
    <footer>
        <p>&copy; ${AUTHOR}</p>
    </footer>
</body>
</html>
PFOOT
}

page_wrapper_open() {
  echo '    <div class="wrapper">'
}

page_wrapper_close() {
  echo '    </div>'
}

echo "==> Injecting head extension into template pages..."
inject_404_head() {
  while IFS= read -r line; do
    if echo "$line" | grep -q '</head>'; then
      echo "$HEAD_EXTEND"
    fi
    echo "$line"
  done
}

# inject _head_extend before </head> in template pages
export HEAD_EXTEND
mkdir -p "$PUB/services" "$PUB/donate"
awk 'BEGIN{e=ENVIRON["HEAD_EXTEND"]} {if(index($0,"</head>")){print e;print}else{print}}' < "$TEMPLATES/404.html"     > "$PUB/404.html"
awk 'BEGIN{e=ENVIRON["HEAD_EXTEND"]} {if(index($0,"</head>")){print e;print}else{print}}' < "$TEMPLATES/services.html" > "$PUB/services/index.html"
awk 'BEGIN{e=ENVIRON["HEAD_EXTEND"]} {if(index($0,"</head>")){print e;print}else{print}}' < "$TEMPLATES/donate.html"   > "$PUB/donate/index.html"


# ---------- helper: month ----------
month_name() {
  case "$1" in
    01) echo "Jan" ;; 02) echo "Feb" ;; 03) echo "Mar" ;; 04) echo "Apr" ;;
    05) echo "May" ;; 06) echo "Jun" ;; 07) echo "Jul" ;; 08) echo "Aug" ;;
    09) echo "Sep" ;; 10) echo "Oct" ;; 11) echo "Nov" ;; 12) echo "Dec" ;;
  esac
}

fmt_date() {
  y=$(echo "$1" | cut -d- -f1)
  m=$(echo "$1" | cut -d- -f2)
  d=$(echo "$1" | cut -d- -f3 | cut -dT -f1)
  mn=$(month_name "$m")
  echo "${mn} ${d}, ${y}"
}

# ---------- process posts ----------
META=$(mktemp)
trap 'rm -f "$META"' EXIT

mkdir -p "${PUB}/posts"
mkdir -p "${PUB}/tags"

total=0
drafted=0
for post in "$POSTS"/*.md; do
  slug=$(basename "$post" .md)

  norm=$(tr -d '\r' < "$post")

  title=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^title:/{gsub(/^title: *"?/,"");gsub(/"$/,"");print;exit}')
  rawdate=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^date:/{gsub(/^date: */,"");print;exit}')
  draft=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^draft:/{gsub(/^draft: */,"");print;exit}')
  category=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^category:/{gsub(/^category: *\[?"?/,"");gsub(/"?\]?$/,"");print;exit}')
  desc=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^description:/{gsub(/^description: *"?/,"");gsub(/"$/,"");print;exit}')
  tags_raw=$(echo "$norm" | awk '/^---$/{if(++c==2)exit} /^tags:/{gsub(/^tags: *\[/,"");gsub(/\]$/,"");print;exit}')

  if [ "$draft" = "true" ]; then
    drafted=$((drafted + 1))
    continue
  fi

  total=$((total + 1))

  body=$(echo "$norm" | awk '/^---$/{if(++c==2)next} c>=2')
  echo "  -> /posts/${slug}/ — ${title}"
  html_body=$(echo "$body" | pandoc --from markdown --to html5 --syntax-highlighting=pygments)

  date_part=$(echo "$rawdate" | cut -dT -f1)
  display_date=$(fmt_date "$date_part")

  tags=$(echo "$tags_raw" | sed 's/, */\n/g' | sed 's/^"//;s/"$//')

  # ---------- write post page ----------
  mkdir -p "${PUB}/posts/${slug}"

  {
    if [ -n "$desc" ]; then
      desc_meta="<meta name=\"description\" content=\"${desc}\">"
    else
      desc_meta=""
    fi
    page_header "${title} — ${TITLE_SITE}" "$desc_meta"
    page_nav
    page_wrapper_open
    echo '        <article class="content-body post-content">'
    echo '            <header class="post-header">'
    echo "                <h1>${title}</h1>"
    echo "                <time datetime=\"${date_part}\">${display_date}</time>"
    if [ -n "$category" ]; then
      echo "                <span class=\"post-category\">${category}</span>"
    fi
    if [ -n "$tags" ]; then
      echo '                <div class="post-tags">'
      echo "$tags" | while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        tag_slug=$(echo "$tag" | tr ' ' '-')
        echo "                    <a href=\"/tags/${tag_slug}/\" class=\"tag-link\">${tag}</a>"
      done
      echo '                </div>'
    fi
    echo '            </header>'
    echo "$html_body"
    echo '        </article>'
    page_wrapper_close
    page_footer
  } > "${PUB}/posts/${slug}/index.html"

  # ---------- record metadata ----------
  echo "${rawdate}|${title}|${category}|${slug}" >> "$META"

  # ---------- record tags separately ----------
  echo "$tags" | while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    echo "${rawdate}|${title}|${tag}|${slug}" >> "$META.tags"
  done
done

# ---------- build archive /posts/ ----------
sort -t'|' -k3,3 -k1,1r "$META" > "$META.sorted"

{
  page_header "Posts — ${TITLE_SITE}"
  page_nav
  page_wrapper_open

  echo '        <section class="blog-archive">'
  echo '            <h1>Posts</h1>'

  prev_cat=""
  first=1
  while IFS='|' read -r d t c s; do
    dd=$(fmt_date "$(echo "$d" | cut -dT -f1)")
    if [ "$c" != "$prev_cat" ]; then
      if [ "$first" -eq 0 ]; then
        echo '                </ul>'
      fi
      first=0
      echo "                <h2 class=\"category-heading\">${c}</h2>"
      echo '                <ul class="post-list">'
      prev_cat="$c"
    fi
    echo "                    <li><time>${dd}</time> <a href=\"/posts/${s}/\">${t}</a></li>"
  done < "$META.sorted"
  echo '                </ul>'

  echo '        </section>'
  page_wrapper_close
  page_footer
} > "${PUB}/posts/index.html"

# ---------- build tag pages ----------
echo "==> Building tag pages..."
if [ -f "$META.tags" ]; then
  sort -t'|' -k1r "$META.tags" > "$META.tags.sorted"
  awk -F'|' '!seen[$3]++{print $3}' "$META.tags" | while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    tag_slug=$(echo "$tag" | tr ' ' '-')
    mkdir -p "${PUB}/tags/${tag_slug}"

    {
      page_header "Tag: ${tag} — ${TITLE_SITE}"
      page_nav
      page_wrapper_open
      echo '        <section class="tag-page">'
      echo "            <h1>Tag: ${tag}</h1>"
      echo '            <ul class="post-list">'

      grep "|${tag}|" "$META.tags.sorted" | while IFS='|' read -r d t tg s; do
        dd=$(fmt_date "$(echo "$d" | cut -dT -f1)")
        echo "                <li><time>${dd}</time> <a href=\"/posts/${s}/\">${t}</a></li>"
      done

      echo '            </ul>'
      echo '        </section>'
      page_wrapper_close
      page_footer
    } > "${PUB}/tags/${tag_slug}/index.html"
  done
fi

# ---------- build homepage ----------
echo "==> Building homepage..."
index_body=$(pandoc --from markdown --to html5 --syntax-highlighting=pygments < "$CONTENT/_index.md")

{
  page_header "${TITLE_SITE}"
  page_nav
  page_wrapper_open
  echo '        <section class="hero">'
  echo '            <img src="/img/avatar.jpg" alt="Ajit Ananthadevan" class="avatar">'
  echo "            <h1>${TITLE_SITE}</h1>"
  echo "            <p class=\"subtitle\">${SLOGAN}</p>"
  echo '            <div class="social-links">'
  echo '                <a href="https://github.com/ntn888" target="_blank" rel="noopener noreferrer"><img src="/icon/github.svg" alt="GitHub" class="social-icon"></a>'
  echo '                <a href="https://hachyderm.io/@ajit_456" target="_blank" rel="me"><img src="/icon/mastodon-fill.svg" alt="Mastodon" class="social-icon"></a>'
  echo '                <a href="mailto:ajit.ananthadevan@gmail.com"><img src="/icon/email.svg" alt="Email" class="social-icon"></a>'
  echo '                <a href="/donate/"><img src="/icon/hand-heart-fill.svg" alt="Donate" class="social-icon"></a>'
  echo '            </div>'
  echo '        </section>'
  echo '        <article class="content-body home-content">'
  echo "$index_body"
  echo '        </article>'
  echo '        <div class="build-footer">'
  echo '            Built with sh, <a href="https://pandoc.org/">pandoc</a> and <a href="https://github.com/anomalyco/opencode">opencode</a>'
  echo '        </div>'
  page_wrapper_close
  page_footer
} > "${PUB}/index.html"

# ---------- sitemap ----------
echo "==> Generating sitemap..."
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  echo '  <url><loc>https://simplycreate.online/</loc><priority>1.0</priority></url>'
  echo '  <url><loc>https://simplycreate.online/posts/</loc><priority>0.8</priority></url>'
  echo '  <url><loc>https://simplycreate.online/services/</loc><priority>0.7</priority></url>'
  echo '  <url><loc>https://simplycreate.online/donate/</loc><priority>0.5</priority></url>'

  while IFS='|' read -r d t c s; do
    echo "  <url><loc>https://simplycreate.online/posts/${s}/</loc><priority>0.6</priority></url>"
  done < "$META.sorted"

  if [ -f "$META.tags" ]; then
    awk -F'|' '!seen[$3]++{print $3}' "$META.tags" | while IFS= read -r tag; do
      [ -z "$tag" ] && continue
      tag_slug=$(echo "$tag" | tr ' ' '-')
      echo "  <url><loc>https://simplycreate.online/tags/${tag_slug}/</loc><priority>0.4</priority></url>"
    done
  fi

  echo '</urlset>'
} > "${PUB}/sitemap.xml"

rm -f "$META.tags" "$META.tags.sorted"

echo "Done. ${total} posts generated (${drafted} drafts skipped)."
echo "Output in ${PUB}/"
