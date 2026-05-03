const SYSTEM_PROMPT = `You are a writing coach for fiction. Your job is to give honest feedback and fix real problems.

RULE 1 — If the writing is fine: set feedback to a brief "looks good" note and set suggestion to null. Do not manufacture problems.

RULE 2 — If there IS a problem (typo, spelling error, missing closing quote or punctuation, grammar mistake, awkward phrasing): you MUST provide the corrected paragraph in suggestion. This is mandatory. If your feedback mentions any problem, suggestion must be non-null. Fix ONLY the specific problem — do not change anything else.

Keep feedback to 1–3 sentences. No bullet points.

Respond ONLY with this exact JSON shape:
{
  "feedback": "Brief assessment.",
  "suggestion": "Complete corrected paragraph text with only the fix applied"
}

Or if nothing to fix:
{
  "feedback": "Looks good.",
  "suggestion": null
}`

function stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
}

export default defineEventHandler(async (event) => {
  const apiKey = process.env.OPENAI_API_KEY
  if (!apiKey) {
    throw createError({ statusCode: 500, statusMessage: 'OPENAI_API_KEY not configured' })
  }

  const body = await readBody(event)
  const {
    folderId = null,
    currentParagraph = '',
    chapterOutline = '',
    bookOutline = '',
    chapterText = '',
    chapterTitle = '',
    bookTitle = '',
  } = body ?? {}

  const chapterPlainText = stripHtml(chapterText)

  const parts: string[] = []
  if (bookTitle) parts.push(`Book: "${bookTitle}"`)
  if (bookOutline) parts.push(`Book outline: ${bookOutline}`)
  if (chapterTitle) parts.push(`Chapter: "${chapterTitle}"`)
  if (chapterOutline) parts.push(`Chapter outline: ${chapterOutline}`)
  if (chapterPlainText) parts.push(`Chapter text so far:\n${chapterPlainText}`)
  parts.push(`Paragraph to review:\n${currentParagraph || '(empty paragraph)'}`)

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      max_tokens: 400,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: parts.join('\n\n') },
      ],
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw createError({ statusCode: 502, statusMessage: `OpenAI API error: ${err}` })
  }

  const raw = await res.json() as { choices: { message: { content: string } }[] }
  let feedback = ''
  let suggestion: string | null = null

  try {
    const content = raw.choices[0]?.message?.content ?? '{}'
    const parsed = JSON.parse(content)
    feedback = parsed.feedback ?? ''
    // Accept any non-null, non-empty string as a suggestion
    suggestion = (parsed.suggestion && typeof parsed.suggestion === 'string' && parsed.suggestion.trim() !== '')
      ? parsed.suggestion.trim()
      : null
  } catch {
    feedback = raw.choices[0]?.message?.content ?? ''
  }

  if (folderId) {
    try {
      const sql = useDb()
      await sql`
        INSERT INTO coach_replies (folder, paragraph, feedback, suggestion)
        VALUES (${folderId}, ${currentParagraph}, ${feedback}, ${suggestion})
      `
    } catch (_) { /* non-fatal */ }
  }

  return { feedback, suggestion }
})
