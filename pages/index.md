---
layout: default
permalink: "/"
---

Hi! I play drums and help make [records]({% link pages/releases.html %}) in Chicago, including two EPs of my own: {% assign my_releases = site.releases | where: "artist","Spencer Tweedy" | sort:"year" | reverse %}{% for release in my_releases limit:2 %}<span><a href="{{ release.listen }}" style="color:{{ release.color }};"><em>{{ release.title }}</em></a></span>{% unless forloop.last == true %} and {% endunless %}{%- endfor %}.

I have a book coming out this fall about musicians who self-record, made with Lawrence Azerrad and Daniel Topete, called <a href="https://mirrorsoundbook.com/" style="color: hsl(295, 59%, 60%);">Mirror Sound</a>. It’s available for preorder now.

Since the start of quarantine, my family has broadcasted a semi-regular livestream show from our living room, called <a href="https://thetweedyshow.com/" style="color: rgb(75,173,233);">The Tweedy Show</a>. We sell t-shirts and things for social orgs on that site too.

Here, I write <a href="{% link pages/observations/index.html %}" class="with-icon observations-link">Observations</a>, a daily list blog about stuff I saw and things I felt. I also run a tiny audio equipment company called <a href="https://fjordaudio.com/" class="with-icon fjord-link">Fjord Audio</a>, but it’s sorta in hibernation now.

You can sign up for my monthly [newsletter]({% link pages/observations/subscribe.md %}), follow me on <a href="https://twitter.com/{{ site.twitter }}">Twitter</a>, and follow me on <a href="https://instagram.com/{{ site.instagram }}">Instagram</a>. If ya like.

Thank you ☺&#xFE0E;  
Spencer
