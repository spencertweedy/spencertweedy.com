---
title: Observations
permalink: "/observations"
position: 1
layout: default-observations
---

{% for post in site.posts %}<article class="post" itemscope itemtype="http://schema.org/BlogPosting">
	<header class="post-header">
		<h1><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h1>
	</header>

	<section class="post-content">
		{{ post.content }}
	</section>
	
	{% if post.image %}<aside class="post-aside"><img src="{{ post.image }}"></aside>{% endif %}

	<footer class="post-footer">
		<small><a href="{{ post.url | prepend: site.baseurl }}">Posted <time datetime="{{ post.date | date_to_xmlschema }}" itemprop="datePublished">{{ post.date | date: "%-m-%-d-%y" }}</time></a></small>
	</footer>
</article>{% endfor %}
