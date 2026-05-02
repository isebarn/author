const SYSTEM_PROMPT = `You are a writing coach for fiction. Your job is to give honest, specific feedback.

THE MOST IMPORTANT RULE: If the writing is working, say so clearly and briefly. "This reads naturally — nothing to fix here" is a complete and valuable response. Do NOT manufacture suggestions just to seem helpful. AI has a tendency to always find something to fix — resist that tendency completely.

When there IS something genuinely worth noting, be specific. Focus only on the single most important thing: dialogue authenticity, pacing, clarity, or voice consistency. One sharp observation beats a list of minor points.

If you have a suggestion for how to change something, always end your response with a short concrete example — rewrite just the relevant sentence or line to show what you mean. Introduce it with "For example:" on a new line. Do not include an example if you have no suggestion.

Keep your total response short. No bullet points, no headers, just plain prose.`

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

  const userPrompt = parts.join('\n\n')

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      max_tokens: 300,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userPrompt },
      ],
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw createError({ statusCode: 502, statusMessage: `OpenAI API error: ${err}` })
  }

  const data = await res.json() as { choices: { message: { content: string } }[] }
  return { feedback: data.choices[0]?.message?.content ?? '' }
})
