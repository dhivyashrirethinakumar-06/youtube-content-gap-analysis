# Content Investment Gap Analysis — Recommendation

*A data-driven recommendation for content category prioritization, India vs. US YouTube markets*

**Dhivya Shri R** | Self-directed analysis using public YouTube Trending data | PostgreSQL, SQL, Tableau

---

## The Question

Where should a media content team prioritize investment, and where are they currently
over-invested relative to audience demand — based on 520,000+ trending YouTube videos
across India and the US (Aug 2020–Apr 2024)?

---

## Method

Built a Gap Score for each of 17 content categories by ranking demand (average engagement
rate) against supply (trending video volume). Categories with fewer than 1,000 trending
videos were excluded to avoid small-sample distortion.

The resulting Gap Score was then validated two further ways:
- A 3.5-year month-by-month trend check to confirm findings were structural rather than
  a short-term spike
- A channel-level concentration check to assess whether a recommended category was already
  dominated by a small number of incumbent creators

---

## Findings

1. **Gaming is India's most underserved high-demand category.** Engagement rate of ~0.085
   — the highest of any reliable category — against a comparatively moderate supply of
   14,735 trending videos.

2. **The same category is the most oversaturated in the US market.** Similar engagement
   (~0.058) is spread across nearly 4× the content volume (53,242 trending videos),
   diluting return on any single piece of content.

3. **The divergence is structural, not a snapshot artifact.** India's Gaming engagement
   rate sits above the US figure in nearly every month across the full 3.5-year window,
   holding through normal volatility on both sides — though the gap has moderated somewhat
   in the most recent year and warrants ongoing monitoring rather than being treated as fixed.

4. **Competitive structure is mixed, not closed.** A clear top tier exists (led by Techno
   Gamerz, ~1,050 trending appearances), but the next 25+ channels form a fragmented,
   gradually-declining tail with no single runner-up dominating — indicating room for
   differentiated new entrants beneath the top tier.

---

## Recommendation

> Prioritize Gaming content investment for the India market specifically — not as a global
> strategy. Sustained, multi-year demand is outpacing current supply, and while the
> established top tier (led by Techno Gamerz) warrants differentiated rather than directly
> competitive positioning, the fragmented mid-tier of creators presents genuine room for entry.

---

## Limitation

This analysis measures engagement on content that already reached trending status, not true
audience demand across all uploads, and does not account for production cost differences
across categories. A full investment decision would also weigh content production cost and
monetization rate by category, which were outside the scope of this dataset.
