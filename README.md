# spencertweedy.com

## Why Is This Repository Public?

For fun! I want to let any curious people see how my website works. If you have suggestions, please let me know in a comment, email, or pull request.

## How It Works

*As of January 18, 2023*

The site uses a static site generator, [Jekyll](https://jekyllrb.com/), to turn these source files into a website.

Jekyll takes each file from 'pages', populates it with appropriate content from 'content', and processes it with the appropriate layout from '\_layouts'. Static assets such as CSS, fonts, and images are stored in 'assets', with the exception of post images, which are stored in the '\_uploads' directory in 'content' (so that Jekyll and Netlify CMS can treat it as a 'collection'). [PostCSS](https://postcss.org) processes stylesheets from 'assets > stylesheets > postcss_source' and places them in 'postcss_dist' so that Jekyll can ingest them. I use the [Tailwind CSS](https://tailwindcss.com) plugin for PostCSS.

Jekyll uses a templating language called [Liquid](https://shopify.github.io/liquid/), so even if a file’s extension is HTML or MD (for Markdown), it may still contain special Liquid tags.

[Netlify](https://www.netlify.com/) watches this GitHub repository and automatically builds the site when there are new commits. Certain files, like 'netlify.toml' and '\_redirects' tell Netlify how to build the site.

I manage the site’s content with [Netlify CMS](https://www.netlifycms.org/), which is hosted and configured in the 'admin' folder.

I use [Umami](https://umami.is) to log anonymous, basic traffic data and no third party can access it.

## Copyright/license

I reserve all rights to the site and its contents.
