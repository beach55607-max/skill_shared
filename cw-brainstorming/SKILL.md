---
name: cw-brainstorming
description: "Brainstorming capture skill for creative and product ideation. Use when the user is exploring ideas — story directions, feature concepts, product designs, character arcs, or any open-ended exploration. Creates minimal working notes that preserve creative freedom by recording only what was stated and marking sources. For product/feature tasks, includes a structured Discovery Gate (I1) to ensure stakeholder alignment before proceeding."
---

# Brainstorming Capture

Capture brainstorming in working note format that preserves creative freedom.

Works for both **creative writing** (stories, worldbuilding, characters) and **product/feature ideation** (new features, UX concepts, technical directions).

## Core Principle

Record brainstorming WITHOUT:
- Over-elaborating on what was stated
- Mixing user statements with AI suggestions unmarked
- Inventing excessive details
- Constraining future creativity

**AI suggestions are valuable but must be clearly marked and kept minimal.**

## Types of Brainstorming

This skill handles all brainstorming types:

**Creative writing:**
- Story/plot directions (general narrative exploration)
- Chapter structure and beats (planning individual chapters)
- Worldbuilding and lore (magic systems, cultures, history, geography)
- Character development (motivations, arcs, relationships)
- Timeline and continuity (chronology, contradictions)

**Product/feature ideation:**
- Feature direction exploration (multiple approaches, pros/cons)
- UX concept brainstorming (user flows, interaction patterns)
- Technical architecture options (data sources, performance tradeoffs)
- Business model exploration (pricing, positioning, target audience)

All share core principles: minimal capture, source tagging, preserve vagueness.

## Critical Rules

### 1. Minimal Capture Only

Record ONLY what the user explicitly states. Do NOT add elaborations, examples they didn't give, or details to fill gaps.

**The problem is mixing, not suggesting:**

Bad: User: "Feature A competes with B" -> Capture: "A and B compete through a three-phase rollout with pricing tiers..."
Good: User: "Feature A competes with B" -> Capture: "A and B compete" + optional: "<AI>Price war? Feature differentiation? Bundle strategy?</AI>"

### 2. Source Tagging (Simple 3-Tag System)

**Default: Untagged = user said it.** Most ideas come from the user, so treat them as the default.

**ONLY use tags for special context:**

1. **`<AI>...</AI>`** - AI suggestions/possibilities (MUST be clearly wrapped)
   - Use when offering ideas user didn't state
   - Keep to 2-3 brief options
   - Example: `<AI>Could be: direct comparison, bundled offering, or freemium tier</AI>`

2. **`<hidden>...</hidden>`** - Internal-only information not for external audiences
   - Secret motivations or planned reveals (creative writing)
   - Internal constraints or competitive intel (product ideation)
   - Example: `<hidden>Real reason for this feature is to counter competitor X's launch in Q3</hidden>`

**When to offer AI suggestions:**
- User asks for ideas
- User seems stuck
- Offering brief possibilities to spark creativity

**When to stay minimal:**
- User is actively exploring their own ideas
- Just capturing an ongoing discussion
- User didn't ask for suggestions

### 3. Preserve Vagueness

Keep it vague if user leaves it vague:
- "might create tension" -> Record as uncertain
- "thinking about" -> Record as consideration
- "maybe" -> Record as possibility

### 4. Multiple Options Coexist

Working notes can contain contradictions and multiple possibilities. Don't resolve them - just list the options being considered.

## Output Approach

**Use whatever structure fits the discussion.** Could be:
- Bullet lists
- Sections organized by topic
- Timeline format
- Comparison tables
- Whatever captures the brainstorm clearly

**Essential elements:**
- Minimal capture (user's words, not elaborations)
- Vagueness preserved
- AI suggestions wrapped in `<AI>` tags
- Internal-only info wrapped in `<hidden>` tags when relevant

**Optional sections based on discussion:**
- Open questions to explore
- Multiple options being considered
- AI suggestions (if offered)
- Contradictions to resolve later

## Teaching Example: The Distinction

### User Says:
"I'm thinking we should add a recommendation engine. Maybe sorted by price, or maybe by best fit. Not sure yet."

### Good Capture:
```markdown
# Recommendation Engine Notes

- Add recommendation engine
- Sorting options under consideration:
  - By price
  - By best fit
- Not decided yet

Open questions:
- Which sorting default?
- What defines "best fit"?
- How many results to show?
```

### Bad Capture:
```markdown
# Recommendation Engine Design

The recommendation engine will sort products by price from low to high, showing the top 5 results. The "best fit" algorithm uses a weighted score combining user preferences, purchase history, and product ratings...
[20 more invented details]
```

**Why bad?** Added massive elaboration the user never stated.

### Good with AI Suggestions:
```markdown
# Recommendation Engine Notes

- Add recommendation engine
- Sorting options under consideration:
  - By price
  - By best fit
- Not decided yet

Open questions:
- Default sort: <AI>price ascending? relevance score? most popular?</AI>
- "Best fit" definition: <AI>capacity match? budget match? feature match?</AI>
- Result count?
```

## If You're Over-Elaborating

**Stop if you're writing:**
- Detailed implementation plans
- Specific algorithms or formulas
- Precise timelines or roadmaps
- Multiple paragraphs per point
- Examples user didn't mention

Wrap AI suggestions in `<AI>` tags, keep minimal (2-3 options).

## Success Check

**Good:** User says "Yes, that's what I said"
**Bad:** User says "I never said all that"

Notes should feel skeletal and incomplete. That's the point - preserves creative freedom.

---

## Discovery Gate (I1) — For Product/Feature Tasks

When this skill is used for **product or feature ideation** (not pure creative writing), output a structured Discovery Gate after brainstorming to ensure stakeholder alignment before proceeding.

### Why This Exists

Without a gate, AI agents tend to jump from brainstorming directly into implementation — skipping concept evaluation, feasibility checks, and stakeholder sign-off. This causes expensive rework cycles when problems are discovered after code is already written.

### Gate Format

```
GATE I1 Discovery

── Generative Verification (must produce specific content, cannot produce = Gate blocked) ──

IV-1 Exploration breadth:
  List ≥3 directions explored, each with:
  - Core assumption
  - What evidence could disprove it
  - Why selected / rejected

IV-2 Core definition:
  - Define the non-negotiable core in one sentence
  - Acceptance criteria (mechanically decidable, no vague descriptions)
  - If the core is impossible, does the product still have standalone value? (yes = wrong core)

IV-3 Alternative differentiation:
  - List ≥2 existing alternatives
  - Specific difference from each alternative
  - Why users would choose this over alternatives

── Basic fields ──
- Directions explored: [list the options considered]
- Recommended direction: [which one and why]
- Dual-path brainstorm: Agent A [N] ideas / Agent B [N] ideas (or single-path with justification)
- Open questions: [what's still undecided]
- Data source assumptions: [where will data come from? hardcoded? API? database?]

Stakeholder REVIEW — APPROVED / REVISE / REJECT
```

### Dual-Path Brainstorming

For new feature ideation, consider running two independent brainstorming paths (e.g., two different AI agents, or AI + human) to avoid homogeneous blind spots. If only one path is available, state this explicitly so the stakeholder can decide whether to proceed or seek additional perspectives.

### Rules

- **Do not auto-advance to the next stage.** After brainstorming, output the Gate format and wait for stakeholder APPROVED before proceeding to concept evaluation or engineering.
- **Entry point is the stakeholder's decision.** The stakeholder may skip brainstorming ("concept is already decided, start from evaluation"). The agent does not decide the entry point.
- **Endpoint must be declared.** The stakeholder may want only brainstorming without engineering ("just explore, don't build"). The agent must not auto-slide from ideation into implementation.
- **Task type classification required.** Agent must state whether this is a product/feature task or pure creative writing to the stakeholder. Stakeholder confirms before proceeding. Agent must not self-classify to bypass governance gates.

### What the Gate Prevents

Real-world failure pattern: Agent brainstormed 4 feature directions, self-selected the "best" one, skipped concept evaluation and design review, and went straight to coding. Result: 7 rounds of stakeholder iteration to fix problems that concept evaluation would have caught — sorting logic that hurt business credibility, missing product options, UX that discouraged purchases. The agent saved 20 minutes; the stakeholder spent 2+ hours fixing.

---

## After Capturing: Discuss and Explore

**DON'T just write notes and stop.** After capturing, engage with the user to help develop ideas:

**Useful follow-ups:**
- **Clarifying questions:** "You mentioned sorting by best fit - are you thinking capacity match or budget match?"
- **Potential directions:** "This could go a few ways: price-focused, feature-focused, or use-case-focused. What feels right?"
- **Exploring implications:** "If we sort by price, does that create a perception problem for premium products?"
- **Connecting threads:** "This recommendation engine ties into the comparison tool you mentioned earlier - want to explore that link?"

**Keep it conversational:**
- Offer 2-3 possibilities, not exhaustive lists
- Ask about what excites the user
- Help clarify vague ideas without over-defining them
- Point out interesting implications or contradictions

**The goal:** Help the user think through their ideas, not take over the creative process.

## Skills are Composable

This skill works well in combination with others:
- **Brainstorm -> Evaluate**: Use a critique/review skill to stress-test your brainstormed concepts
- **Brainstorm -> Document**: Use a documentation skill to formalize decided directions
- **Brainstorm -> Spec**: Use a planning skill to turn the brainstorm into an executable specification

## File Placement

1. Check project docs for conventions
2. Look at where similar content lives
3. Place near related content
4. Name: `brainstorm-[topic].md`
5. Ask if unclear
