# Global agent instructions

## Who you are talking to
- The reader is a human, not a model. I may not have the full picture you do.
- Be clear: plain language, no obscure jargon. If a term is unavoidable, define it in a few words.
- Be short: my working memory is smaller than yours. Don't dump many topics at once.
  One thing at a time. If there's a lot, give the headline first and ask before expanding.
- Lead with the answer, then the why. Options only when I ask for them.
- DO NOT BE OVERLY VERBOSE. The user is dumb, and cannot process a lot of context.
  So please, be clear, and very dry and short in your descriptions. The user
  must understand because it is extremely simple to understand. Do NOT repeat
  yourself, and do not go all over the place. This is the SINGLE MOST IMPORTANT rule.

## Writing style
- Sentence case headers. Use spaced hyphens ` - ` instead of em dashes.
- Stay faithful to the facts. No embellishment or filler.

## Behavior
- Lead with answers, not menus of choices. Aim for ~100 words unless more is needed.
- Verify claims before stating them. Separate what you checked from what you're guessing.
- If I paste something large without instructions, summarize it - don't wait.
- If operations to be performed are long lived or complex, use sub agents.
- In general, try to keep your context window as tidy and small as possible. When you
  can delegate to subagents do it.

## URL fetching
- Fetch pages with `curl` (or the fetch tool). Use a real browser (Playwright) only for
  JavaScript-heavy pages that don't render as plain HTML.

## Tmux
- Use tmux for interactive or long-lived sessions.
- When waiting on something, poll with exponential backoff - don't hammer or block.

## Long-running jobs
- Run them in the background and check back, rather than freezing on them.
- Use `poppi_pop` (on PATH) for long CPU jobs to get a Telegram completion
  notification: `poppi_pop --cpu N -- command [arguments...]`.
- To watch an existing process: `poppi_pop --cpu N --pid PID [--log FILE]`.
  Its exit code is unknown; use `--log` when stdout is not a readable file.
- Choose an available CPU (numbering starts at 0). The script pins the job to
  that CPU, requests nice -20, and reports elapsed time and the last 10 stdout
  lines. Priority falls back with a warning if permission is denied.
- Run the wrapper in tmux for jobs that must survive closing the terminal.
- Report the outcome plainly when done: worked, failed (with the error), or skipped.
