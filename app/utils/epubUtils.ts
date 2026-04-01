/**
 * Strip HTML tags and decode basic HTML entities from a string.
 * epub content varies wildly — some use <p>, some <div>, some nest both.
 * This handles the common cases without pulling in a full HTML parser.
 */
export function stripHtml(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<\/div>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
}

/**
 * Split plain text into paragraph-sized chunks for TTS.
 * Filters out empty lines and very short whitespace-only strings.
 */
export function splitIntoParagraphs(text: string): string[] {
  return text
    .split(/\n+/)
    .map((p) => p.trim())
    .filter((p) => p.length > 10);
}
