# ScreenQR website and SEO

Russian homepage: https://kunilingvistador.github.io/ScreenQR/
English homepage: https://kunilingvistador.github.io/ScreenQR/en/

The homepage answers the main intent: read a QR directly from a Mac screen. Guides cover distinct tasks: PDF on screen, screenshot/clipboard, screen access, and recognition failures. Each has a Russian and English counterpart; privacy also has both languages. No doorway pages for synonymous keywords, invented ratings or demand estimates.

Build with `python3 scripts/build-website.py`; validate actual generated HTML with `python3 scripts/validate-website.py`. Source is in scripts/build-website.py and website/assets; website/dist is disposable output. GitHub Actions generates and deploys the static artifact. No framework, external fonts, analytics or cookie banners. JavaScript only enhances the explicit sample demonstration; content and navigation work without it.

Self canonicals, reciprocal language links, titles, descriptions, JSON-LD, sitemap and 404 are checked. SoftwareApplication schema has factual system/version/free price, no invented aggregateRating. It does not promise a rich result. A project-level /ScreenQR/robots.txt is not the host-root robots.txt used by crawlers; do not claim it controls crawling. Submit the sitemap URL directly in Search Console if ownership access is available.

One contextual homepage link leads to ProfileDock. The reverse link should only be published after ScreenQR is live. Reciprocal links are for useful discovery, not a guaranteed ranking boost.

After deployment: check HTTP responses, download links and actual pages; submit the sitemap in a verified Search Console property if accessible. Query/impression data should inform later copy. GitHub asset downloads, site visits and installed apps are different metrics; none is substituted for another. No ranking or indexing guarantee.

Primary references checked 9 October 2026:
- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- https://developers.google.com/search/docs/crawling-indexing/links-crawlable
- https://developers.google.com/search/docs/appearance/structured-data/software-app
