# spencertweedy.com

## Why Is This Repository Public?

For fun! I want to let any curious people see how my website works. If you have suggestions, please let me know in a comment, email, or pull request.

## How It Works

*As of August 3, 2025*

The site uses a static site generator, [Jekyll](https://jekyllrb.com/), to turn these source files into a website.

Jekyll takes each file from 'pages', populates it with content from 'content', and wraps it with HTML defined by '\_layouts'. Static assets like CSS, fonts, and images are stored in 'assets', with the exception of post images, which are stored in the '\_uploads' directory in 'content' (so that Jekyll and Netlify CMS can treat it as a 'collection'). [PostCSS](https://postcss.org) processes stylesheets from 'assets > stylesheets > postcss_source' and places them in 'postcss_dist' so that Jekyll can ingest them. I use the [Tailwind CSS](https://tailwindcss.com) plugin for PostCSS.

The 'shows-fetcher' plugin fetches information about my shows from a remote server (running [Baserow](https://baserow.io/)) and compiles them into a JSON file so that Jekyll can ingest them.

Jekyll uses a templating language called [Liquid](https://shopify.github.io/liquid/), so even if a file’s extension is HTML or MD (for Markdown), it may still contain special Liquid tags.

[Netlify](https://www.netlify.com/) watches this GitHub repository and automatically builds the site when there are new commits. Certain files, like 'netlify.toml' and '\_redirects' tell Netlify how to build the site.

I use [Plausible](https://plausible.io) to log anonymous, basic traffic data and no third party can access it.

## Copyright/license

I reserve all rights to the site and its contents. But the way its built is as free as the wind.
