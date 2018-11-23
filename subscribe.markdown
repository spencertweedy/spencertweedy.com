---
title: Subscribe
permalink: "/subscribe"
position: 2
layout: page
---

## Subscribe via email
{% if site.tinyletter %}<section>
		<form action="https://tinyletter.com/{{ site.tinyletter }}" class="subscribe-form" method="post" target="popupwindow" onsubmit="window.open('https://tinyletter.com/{{ site.tinyletter }}', 'popupwindow', 'scrollbars=yes,width=800,height=600');return true">
            <label for="tlemail">Enter your email address</label>
            <input type="text" name="email" id="tlemail" aria-label="Enter your email address" placeholder="Your email address" />
            <input type="hidden" value="1" name="embed"/>
            <input type="submit" value="Subscribe" />
        </form>
</section>{% endif %}