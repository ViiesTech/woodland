# The Woodlands Series - Legal Documents

This directory contains the legal documents for The Woodlands Series mobile application.

## Files

- **TERMS_OF_SERVICE.md** - Terms of Service document
- **PRIVACY_POLICY.md** - Privacy Policy document

## Hosting Instructions for Hostinger

### Step 1: Upload Files to Hostinger

1. Log in to your Hostinger hosting account
2. Navigate to File Manager or use FTP
3. Upload the markdown files to your public_html directory (or a subdirectory like `/legal/`)

### Step 2: Convert to HTML (Optional but Recommended)

For better web display, you can:

**Option A: Use a Static Site Generator**
- Use Jekyll, Hugo, or similar to convert markdown to HTML
- Host the generated HTML files

**Option B: Use a Markdown to HTML Converter**
- Use online tools like [Markdown to HTML](https://www.markdowntohtml.com/)
- Convert the .md files to .html
- Upload the HTML files to Hostinger

**Option C: Use GitHub Pages (Free Alternative)**
- Create a GitHub repository
- Upload these markdown files
- Enable GitHub Pages
- Get free hosting with URLs like: `https://yourusername.github.io/repo-name/TERMS_OF_SERVICE.html`

### Step 3: Access URLs

After uploading to Hostinger, your URLs will be:
- `https://woodland.codefied.co/TERMS_OF_SERVICE.html`
- `https://woodland.codefied.co/PRIVACY_POLICY.html`

Or if in a subdirectory:
- `https://woodland.codefied.co/legal/TERMS_OF_SERVICE.html`
- `https://woodland.codefied.co/legal/PRIVACY_POLICY.html`

**Note:** The app is already configured to use these URLs:
- Terms of Service: `https://woodland.codefied.co/TERMS_OF_SERVICE.html`
- Privacy Policy: `https://woodland.codefied.co/PRIVACY_POLICY.html`

### Step 4: Use in Play Store

When submitting to Google Play Store, provide these URLs in:
- **Privacy Policy URL**: `https://woodland.codefied.co/PRIVACY_POLICY.html` (Required field)
- **Terms of Service URL**: `https://woodland.codefied.co/TERMS_OF_SERVICE.html` (Optional but recommended)

## Quick Setup Script

If you have Node.js installed, you can use this simple script to convert markdown to HTML:

```bash
npm install -g markdown-pdf
markdown-pdf TERMS_OF_SERVICE.md -o TERMS_OF_SERVICE.html
markdown-pdf PRIVACY_POLICY.md -o PRIVACY_POLICY.html
```

## Notes

- Make sure the URLs are publicly accessible (no login required)
- Update the "Last Updated" dates when you make changes
- Keep these documents in sync with the app's legal screens
- Consider adding a robots.txt file to allow search engines to index these pages

