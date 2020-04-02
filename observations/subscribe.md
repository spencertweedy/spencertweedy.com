---
title: Newsletter
permalink: "/observations/subscribe"
layout: obs-page
---

My favorite **OBSERVATIONS** posts from the preceding month, sent on the first Saturday of the month. A less-than-five-minute read.

{% include subscribe-box.html %}

***

You can also subscribe via [Twitter](https://twitter.com/{{ site.obs_twitter }}), [Instagram](https://instagram.com/{{ site.obs_instagram }}), or [RSS]({% link feed.xml %}).

***

### Past newsletters

<ul>
  {% for newsletter in site.newsletters reversed %}
    <li>
      <a href="{{ newsletter.url }}">{{ newsletter.title }}</a>
    </li>
  {% endfor %}
</ul>