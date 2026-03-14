---
name: sytex-blog-publish
description: >-
  Research competitors (Sitetracker, ServiceNow), draft and publish approved Sytex blog posts
  into the Sytex website repo with EN/ES/PT-BR variants. Use when the user wants to create
  a blog draft, review competitor content, or publish a post on the Sytex website.
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(cd *)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - WebSearch
  - WebFetch
---

# Sytex Blog Publish

Research, draft, and publish blog posts to the Sytex website with EN, ES, and PT-BR variants.

## Repository

- **Repo**: `Sytex/Landing` (GitHub)
- **Branch**: `nextjs-landing-page` (source of truth, Next.js 15)
- **Blog content file**: `lib/content/blog-posts.ts`
- **Domains**: `www.sytex.io` (EN), `es.sytex.io` (ES), `pt-br.sytex.io` (PT-BR)

## Blog Post Schema

Posts are TypeScript objects in `lib/content/blog-posts.ts`. Three arrays:
- `postsEn` (English)
- `postsEs` (Español)
- `postsPtBr` (Português BR)

Each post has these fields:
```typescript
{
  slug: string;      // URL-friendly identifier (unique per locale)
  title: string;     // Locale-specific title
  excerpt: string;   // Short summary for blog listing cards
  date: string;      // Human-readable date (e.g., "March 10, 2026")
  image: string;     // CDN URL to featured image
  content: string;   // Full article body (\n\n for paragraphs, "- " for bullets)
}
```

## When to use
- User wants to research competitors and create a blog draft
- User approved a blog draft and wants it published on the website
- User wants a Sytex blog post published with EN, ES, and PT-BR variants

## Workflow

### Phase 1: Research & Draft

1. **Competitor analysis** — Research what Sitetracker and ServiceNow published **in the last 7 days**
   (since the previous Tuesday's run). Focus on:
   - **Sitetracker** (`sitetracker.com`): New posts, topics, keywords, positioning, content gaps.
   - **ServiceNow** (`servicenow.com/blogs`): Field service / telecom content, messaging angles.
   - Identify topics where Sytex can differentiate or fill gaps.
   - Note competitor keywords and SEO angles to compete against or complement.
   - If no new competitor content was published, note that and base the draft on existing gaps or trending industry topics.
2. **Draft content** — Write the article in English with:
   - SEO-optimized title and slug.
   - Excerpt/summary for blog listing cards.
   - Full article body with clear structure (intro, sections, conclusion).
   - Tone: professional but accessible, focused on field operations / telecom.
3. **Publish draft to Slite** — Use the `slite` skill to create a new note inside the **Blog Posts** folder
   (parent ID: `rfY0DyxoVoq6VF`). One note per draft. Include: title, slug, excerpt, date, and full article body.
   Note: Slite has a content size limit per request — use `append` to add content in sections if needed.
4. **Notify for review** — Send a message to the channel notifying that the draft is ready for review
   in Slite, including the Slite note link and a brief summary of the topic and competitive angle.

### Phase 2: Publish (triggered after user approval)

5. **Translate** — Generate ES and PT-BR versions from the approved English draft.
6. **Clone/update repo** — Clone `Sytex/Landing` and checkout `nextjs-landing-page` branch.
7. **Add blog posts** — Edit `lib/content/blog-posts.ts`:
   - Add the new post object to `postsEn`, `postsEs`, and `postsPtBr` arrays.
   - Place new posts at the TOP of each array (newest first).
   - Ensure slugs are localized appropriately per language.
   - Date format: human-readable (e.g., "March 10, 2026" / "10 de marzo de 2026" / "10 de março de 2026").
8. **Create PR** — Create a pull request on `Sytex/Landing` targeting `nextjs-landing-page`.
9. **Wait for approval** — Only merge after explicit user approval.

## Guardrails
- Do NOT publish without explicit user approval.
- Default to no cover image unless the user provides one.
- Keep the website format aligned with existing Sytex blog posts (check existing entries for style).
- Treat the webhook URL as a secret — never print it in responses.
- Always create a PR for review, never push directly to the branch.
- Competitor research is mandatory before drafting — do not skip this step.
