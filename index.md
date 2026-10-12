---
layout: default
title: Home
---

<section class="hero-section">
  <h1>サークル名へようこそ</h1>
  <p>電子工作キット、アダプタボード、各種技術同人誌を製作・頒布しています。</p>
</section>

<section class="section">
  <div class="section-header">
    <h2>最新の頒布物 (Featured Works)</h2>
    <a href="{{ '/works/' | relative_url }}" class="more-link">すべて見る &rarr;</a>
  </div>
  <div class="works-grid">
    {% assign sorted_works = site.works | sort: "order" %}
    {% for work in sorted_works limit:3 %}
      {% include work-card.html %}
    {% endfor %}
  </div>
</section>

<section class="section">
  <div class="section-header">
    <h2>参加イベント情報 (Events)</h2>
    <a href="{{ '/events/' | relative_url }}" class="more-link">イベント一覧 &rarr;</a>
  </div>
  <div class="events-list">
    {% for event in site.events limit:2 %}
      <article class="event-card">
        <div class="event-meta">
          <time datetime="{{ event.event_date }}">{{ event.event_date }}</time>
          <span class="event-space">スペース: {{ event.space }}</span>
        </div>
        <h3 class="event-title"><a href="{{ event.url | relative_url }}">{{ event.title }}</a></h3>
        <p class="event-venue">会場: {{ event.venue }}</p>
      </article>
    {% endfor %}
  </div>
</section>
