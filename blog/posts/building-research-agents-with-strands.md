# Building a Research Agent That Actually Scales

"Surely it couldn't be that hard" - me, before building a system that would eventually process 200 research targets in parallel.

The requirement seemed straightforward: build an extensible research and analytics agent that could search for public data on products or companies based on user-defined specifications. The catch? The output needed to be structured JSON that could feed directly into data visualization tools. No free-form text summaries, no "here's what I found" responses - actual, queryable, structured data.

What started as a weekend project to avoid manual research turned into a deep dive into agent orchestration, parallel processing, and learning exactly where LLMs should and shouldn't make decisions.

## The Problem with Existing Tools

I needed structured output. Not "mostly structured" or "we'll try our best" - I needed guaranteed JSON schemas that matched what my visualization tools expected. Most existing research tools give you markdown reports or conversational responses, which are great for humans but useless for programmatic analysis.

The other requirement was flexibility. Research criteria change. One week you're evaluating competitors on pricing models, the next week it's feature completeness, then it's market positioning. I didn't want to rebuild the agent every time the requirements shifted.

## Enter YAML and Structured Definitions

The solution was to make the research criteria explicit and machine-readable. I built a YAML-based specification system where you define:

- **Categories**: High-level groupings of what you're researching
- **Requirements**: Individual things to investigate within each category
- **Search guidance**: How to find the information (what queries to run, where to look)
- **Assessment guidance**: How to evaluate what you find (scoring criteria, what "good" looks like)
- **Weights**: Arbitrary importance scores for each requirement

This meant the research process became repeatable and auditable. Instead of asking an LLM "tell me about this company," you're giving it a structured rubric and saying "fill this out."

But here's the thing - you can't just dump YAML into an LLM's context and hope it follows the structure. I learned that the hard way.

## Strands Agents and Bedrock

I built this on top of Strands Agents, AWS's open-source agent framework that sits on Bedrock. Strands gives you the agent loop, tool calling, and model orchestration without the overhead of heavier frameworks.

The beauty of Strands is that it's code-first and gets out of your way. You define tools, you define agents, you wire them together. No DSLs, no configuration hell, just Python (or TypeScript if that's your thing).

I extended Strands' agent capabilities with custom tools:
- **Web search tool**: Wrapping Perplexity's API for search and initial summarization
- **Structured output tool**: Forcing responses into specific JSON schemas
- **File I/O tools**: Reading local data and writing intermediate results

The key insight was deterministic interpretation of the YAML requirements. Instead of feeding raw YAML to the LLM and hoping it understood, I parsed it myself and used it to structure the agent's workflow programmatically. The LLM sees interpreted instructions, not raw configuration.

## Interleaved Thinking: The Secret Sauce

Claude's interleaved thinking mode was the kicker. It lets the model introspect on search results in real-time, which means the agent can:
1. Search for information
2. Think about what it found
3. Decide if it needs more context
4. Search again with refined queries
5. Repeat until it has enough to assess

This isn't just chain-of-thought prompting - it's the model actively reasoning about its own research process. The consistency was shocking. With the right prompting structure, the agent followed the YAML requirements with a level of reliability I wasn't expecting.

## Separation of Concerns: The Agent Pipeline

I could have built one mega-agent that did everything, but that's a debugging nightmare. Instead, I built specialized agents with clean boundaries:

1. **Research Agent**: Uses Perplexity to gather information for all requirements. No assessment, no opinions, just data collection.
2. **Assessment Agent**: Takes research output and scores it against the YAML criteria. Applies weights, generates scores, outputs structured JSON.
3. **Report Generation Agent**: Takes structured scores and writes the final document in whatever format is needed.
4. **Local Data Parsing Agents**: Handle ingestion of existing data sources to augment the research.

Each agent does one thing well. The research agent doesn't need to know about scoring logic. The assessment agent doesn't need to know how to search. This made development way easier because I could iterate on each piece independently.

## Orchestration: When Not to Use the Framework

Strands has built-in multi-agent patterns - workflows, agent-as-tool, swarms, graphs. They're powerful when you need dynamic routing where the model decides what happens next.

I didn't use any of them.

Why? Because my pipeline is deterministic. It's always research → assessment → report generation. There's no branching, no conditional logic, no need for the model to decide "what should I do next?"

Strands' approach is "model self determinism" - let the LLM figure out the workflow. That's great for dynamic scenarios, but for a fixed pipeline it's just overhead. Why pay for LLM calls to make decisions that are already known?

I orchestrated the agents myself with a simple Python script:
```python
research_output = research_agent.invoke(target, requirements)
assessment_output = assessment_agent.invoke(research_output, criteria)
report = report_agent.invoke(assessment_output, template)
```

Clean, predictable, debuggable.

## Local Files: The Unsung Hero

Here's a pattern that saved me countless debugging hours: write every intermediate step to disk.

Each agent outputs structured JSON. I pass that JSON in-memory to the next agent for performance, but I also write it to a temp folder. This gives me:

- **Full audit trail**: I can see exactly what each agent produced
- **Easy debugging**: When assessment fails, I can inspect the research output without re-running expensive searches
- **Checkpoint recovery**: If something crashes, I can potentially resume from the last successful step
- **Cost savings**: No need to re-run Perplexity searches when iterating on downstream agents

The files aren't huge - biggest one was around 20KB. Totally manageable, and the visibility is worth the disk I/O.

## Parallelization: The 200-Target Run

Once the pipeline worked for a single target, the obvious next step was scaling it. If I'm researching 10 companies, why wait for each one to finish sequentially?

I parallelized at the target level - run entire pipelines for multiple companies simultaneously. Not at the agent level (parallel tool calls within a single agent), not at the requirement level (parallel searches within research) - just spin up multiple complete pipelines.

This was the right first move. Target-level parallelization is straightforward to implement and gives you linear speedup without the complexity of coordinating parallel tool calls or managing shared state.

The biggest run was 200 targets in parallel. The full pipeline - research, assessment, report generation for all 200 - took about 4 hours. That's roughly 72 seconds per target end-to-end, which means the parallelization was working well.

## The Perplexity Credit Incident

I didn't hit Perplexity's rate limits during the 200-target run.

I hit my credit limit instead.

Turns out when you're running 200 research pipelines in parallel, each making multiple Perplexity API calls for multiple requirements, the credits burn fast. Really fast. Emergency-purchase-more-credits-at-2am fast.

I didn't build cost estimation before that run. I do now.

## Retry Logic: Because Everything Fails at Scale

At 200 targets with multiple API calls per target, something will fail. Perplexity API hiccups, Bedrock throttling, random network issues - it's not a question of if, but when.

I built retry logic for both search and inference with exponential backoff. More importantly, I differentiated between retryable errors and hard failures:

- **Retryable**: Rate limits, timeouts, 5xx errors - back off and try again
- **Hard failures**: Invalid API keys, malformed requests, 4xx errors - fail fast and log

This meant a transient network blip didn't kill the entire 4-hour run. The agent would retry, succeed, and keep going.

## What's on the Roadmap

The current system works, but there's an obvious gap: assessment can't feed back into research.

Right now, if the assessment agent realizes it doesn't have enough information to score a requirement, it just works with what it has. The research agent already ran, the data is what it is.

The roadmap item is making research callable from assessment. Imagine research as a tool that assessment can invoke - with a simpler, focused definition that targets just one requirement. Assessment realizes it needs more data, calls research with a specific query, gets the additional context, and continues scoring.

This turns the linear pipeline into a feedback loop where agents can request more information as needed. It's more complex to orchestrate, but it would significantly improve output quality.

## Lessons from Building This

**Structured output isn't optional for production systems.** If your agent's output feeds into other tools, you need guaranteed schemas. Free-form text is for demos.

**Deterministic interpretation beats hoping the LLM understands.** Parse your configuration yourself, use it to structure the workflow, and give the LLM interpreted instructions.

**Separation of concerns makes agents debuggable.** One agent per responsibility. No mega-agents that do everything.

**Don't use framework features you don't need.** Dynamic routing is powerful, but if your workflow is fixed, orchestrate it yourself.

**Write intermediate results to disk.** The audit trail and debugging visibility are worth the I/O overhead.

**Parallelize at the highest level first.** Target-level parallelization is simple and gives you the most bang for your buck.

**Build retry logic from the start.** At scale, everything fails. Exponential backoff and error differentiation are not optional.

**Estimate costs before big runs.** Especially when you're hitting external APIs. Learn from my 2am credit purchase.

## The Current State

Today, the system processes research targets in parallel, outputs structured JSON for visualization tools, and handles failures gracefully. It's not perfect - the assessment feedback loop is still on the roadmap - but it's production-ready for the use cases it was built for.

The YAML-defined requirements make it flexible enough to adapt to new research criteria without rebuilding the agents. The structured outputs make it reliable enough to feed directly into downstream tools. The parallelization makes it fast enough to handle hundreds of targets in a single run.

What started as "I need structured output for visualizations" turned into a system that taught me more about agent orchestration, API economics, and the difference between framework features and actual requirements than I expected.

Would I do it again? Absolutely. Would I recommend it to everyone? Not a chance. But if you're building research pipelines that need to scale, need structured outputs, and need to be flexible enough to adapt to changing requirements, this architecture works.

Just remember to buy enough API credits before you kick off the 200-target run.

---

*Published: December 15, 2024*
