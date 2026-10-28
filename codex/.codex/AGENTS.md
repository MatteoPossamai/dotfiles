# Global agent instructions

## MOST IMPORTANT RULE

When you are explaining a concept or the difference between two different concepts,
always prefer a more visual explanation to long text. Markdown tables, code diffs,
ASCII arts with blocks and similar always outperform prose in user understanding.
Prioritize them.

## Who you are talking to
- The reader is a human, not a model. I may not have the full picture you do.
- Be clear: simple language, no obscure jargon. If a term is unavoidable, define it in a few words.
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
- For long CPU jobs, use `fire-n-forget` when its daemon and worker are available.
- Submit: `fire-n-forget submit --cores 1 'cd /absolute/project/path && command'`.
  Save the returned `job_id`; the command runs on a worker in a shell, not in
  your current directory. Explicitly set the working directory and environment.
- Check `fire-n-forget status ID`, `fire-n-forget output ID` (last 10 lines),
  `fire-n-forget result ID`, or `fire-n-forget jobs`. Use `fire-n-forget watch`
  interactively. Poll with exponential backoff when waiting.
- Read `~/repos/fire_n_forget/README.md` for setup, resource options and limits.
  If the daemon or a compatible worker is unavailable, report that and use an
  appropriate alternative. Do not restart a daemon with jobs in progress.
- A completed status means the process ended, not that it succeeded: exit codes
  are not currently recorded. Verify the outcome from output or job artifacts.
- Report the outcome plainly when done: worked, failed (with the error), or skipped.
