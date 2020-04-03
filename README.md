# spencertweedy.com

## Why Is This Repository Public?

I dunno. Just for fun! I reserve all the rights to the site and its content. But I think it’s fun to let people see how things work, if they wanna see it. Plus, I’m an amateur developer, so if you notice something you think I could improve, please tell me about it.

## How It Works

*As of April 3, 2020*

The site uses a static site generator, [Jekyll](https://jekyllrb.com/), to turn these source files into a website.

Jekyll takes each file from 'pages', populates it with appropriate content from 'content', and processes it with the appropriate layout from '\_layouts'. Static assets such as CSS, fonts, and images are stored in 'assets', with the exception of post images, which are stored in the '\_uploads' directory in 'content' (so that Jekyll and Netlify CMS can treat it as a collection).

[Netlify](https://www.netlify.com/) watches this GitHub repository and automatically builds the site when there are new commits. Certain files, like 'netlify.toml' and '\_redirects' tell Netlify how to build the site.

I manage the site’s content with [Netlify CMS](https://www.netlifycms.org/), which is hosted and configured in the 'admin' folder.