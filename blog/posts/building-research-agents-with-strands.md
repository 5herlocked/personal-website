# Building a Research Agent That Actually Scales

"Surely it couldn't be that hard" - me, before building a system that would eventually process 200 research targets in parallel.

The requirement seemed straightforward: build an extensible research and analytics agent that could search for public data on products or companies based on user-defined specifications. The catch? The output needed to be structured JSON that could feed directly into data visualization tools. No free-form text summaries, no "here's what I found" responses - actual, queryable, structured data.

Most existing research tools give you markdown reports or conversational responses, which are great for humans but useless for programmatic analysis. And research criteria change constantly - one week you're evaluating competitors on pricing models, the next week it's feature completeness. I didn't want to rebuild the agent every time requirements shifted.

## YAML-Defined Research Criteria

The solution was to make the research criteria explicit and machine-readable. I built a YAML-based specification system where you define categories, individual requirements within each category, search guidance for finding information, assessment guidance for scoring, and arbitrary weights for importance.

This made the research process repeatable and auditable. Instead of asking an LLM "tell me about this company," you're giving it a structured rubric.

But you can't just dump YAML into an LLM's context and hope it follows the structure. I learned that the hard way. The key was deterministic interpretation - I parsed the YAML myself and used it to structure the agent's workflow programmatically. The LLM sees interpreted instructions, not raw configuration.

## Strands Agents and Bedrock

I built this on top of Strands Agents, AWS's open-source agent framework that sits on Bedrock. It's code-first and gets out of your way - you define tools, define agents, wire them together. No DSLs, no configuration hell.

I extended Strands with custom tools:
- **Web search tool**: Wrapping Perplexity's API for search and initial summarization
- **Structured output tool**: Forcing responses into specific JSON schemas
- **File I/O tools**: Reading local data and writing intermediate results

## Interleaved Thinking

Claude's interleaved thinking mode was the kicker. The model can search, think about what it found, decide if it needs more context, search again with refined queries, and repeat until it has enough to assess. Not just chain-of-thought prompting - the model actively reasoning about its own research process.

With the right prompting structure, the agent followed the YAML requirements with a level of consistency I wasn't expecting.

## The Agent Pipeline

I built specialized agents with clean boundaries instead of one mega-agent:

1. **Research Agent**: Uses Perplexity to gather information. No assessment, no opinions, just data collection.
2. **Assessment Agent**: Scores research output against YAML criteria. Applies weights, generates scores, outputs structured JSON.
3. **Report Generation Agent**: Takes structured scores and writes the final document.
4. **Local Data Parsing Agents**: Handle ingestion of existing data sources.

Each agent does one thing. This made development easier because I could iterate on each piece independently.

## Orchestration

Strands has built-in multi-agent patterns - workflows, agent-as-tool, swarms, graphs. I didn't use any of them.

My pipeline is deterministic: research → assessment → report generation. No branching, no conditional logic. Strands' "model self determinism" approach is great for dynamic scenarios, but for a fixed pipeline it's just overhead. Why pay for LLM calls to make decisions that are already known?

I orchestrated the agents myself:
```python
def process_target(target: ResearchTarget, requirements: Requirements) -> Report:
    """Process a single research target through the full pipeline."""
    # Research phase - gather data
    research_output = research_agent.invoke(
        target=target,
        requirements=requirements
    )
    
    # Write checkpoint
    write_checkpoint(target.id, "research", research_output)
    
    # Assessment phase - score against criteria
    assessment_output = assessment_agent.invoke(
        research_data=research_output,
        criteria=requirements.assessment_criteria,
        weights=requirements.weights
    )
    
    # Write checkpoint
    write_checkpoint(target.id, "assessment", assessment_output)
    
    # Report generation phase - create final document
    report = report_agent.invoke(
        assessment_data=assessment_output,
        template=requirements.report_template
    )
    
    # Write final output
    write_checkpoint(target.id, "report", report)
    
    return report
```

Each agent outputs structured JSON. I pass it in-memory to the next agent for performance, but also write it to a temp folder. Full audit trail, easy debugging when assessment fails, checkpoint recovery if something crashes, and no need to re-run expensive Perplexity searches when iterating on downstream agents. The files aren't huge - biggest one was around 20KB.

## Parallelization

Once the pipeline worked for a single target, scaling was obvious. I parallelized at the target level - run entire pipelines for multiple companies simultaneously. Not at the agent level or requirement level, just spin up multiple complete pipelines. Straightforward to implement, linear speedup, no complexity of coordinating parallel tool calls or managing shared state.

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor
from typing import List

async def process_targets_parallel(
    targets: List[ResearchTarget],
    requirements: Requirements,
    max_workers: int = 10
) -> List[Report]:
    """Process multiple targets in parallel with controlled concurrency."""
    
    def process_with_error_handling(target: ResearchTarget) -> Report:
        try:
            return process_target(target, requirements)
        except Exception as e:
            logger.error(f"Failed to process {target.id}: {e}")
            # Write error checkpoint for debugging
            write_checkpoint(target.id, "error", {"error": str(e)})
            raise
    
    # Use ThreadPoolExecutor for I/O-bound operations
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        loop = asyncio.get_event_loop()
        tasks = [
            loop.run_in_executor(executor, process_with_error_handling, target)
            for target in targets
        ]
        
        # Gather results, allowing some to fail without stopping others
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
    # Filter out exceptions and return successful reports
    return [r for r in results if isinstance(r, Report)]
```

The biggest run was 200 targets in parallel. The full pipeline took about 4 hours - roughly 72 seconds per target end-to-end.

I didn't hit Perplexity's rate limits during that run. I hit my credit limit instead. Emergency-purchase-more-credits-at-2am fast. I didn't build cost estimation before that run. I do now.

## Building a TUI

Running 200 targets in parallel is great for throughput, terrible for visibility. Which targets are in research? Which are in assessment? Which failed?

I built a Terminal User Interface to visualize the entire pipeline in real-time. This turned out to be one of the most satisfying parts of the project.

Strands already provides telemetry, traces, and logs - but I needed real-time updates for the UI without interfering with agent execution. The solution was an event emitter pattern:

```python
from typing import Callable, Dict, List
from enum import Enum

class AgentEvent(Enum):
    STARTED = "started"
    RESEARCH_COMPLETE = "research_complete"
    ASSESSMENT_COMPLETE = "assessment_complete"
    REPORT_COMPLETE = "report_complete"
    FAILED = "failed"

class AgentObservable:
    """Observable pattern for real-time agent status updates."""
    
    def __init__(self):
        self._observers: Dict[str, List[Callable]] = {}
    
    def subscribe(self, event: AgentEvent, callback: Callable):
        """Subscribe to agent events."""
        if event.value not in self._observers:
            self._observers[event.value] = []
        self._observers[event.value].append(callback)
    
    def emit(self, event: AgentEvent, target_id: str, data: dict = None):
        """Emit an event to all subscribers."""
        if event.value in self._observers:
            for callback in self._observers[event.value]:
                callback(target_id, data or {})

# Global observable instance
agent_observable = AgentObservable()

def process_target(target: ResearchTarget, requirements: Requirements) -> Report:
    """Process a single target with observable events."""
    agent_observable.emit(AgentEvent.STARTED, target.id)
    
    try:
        # Research phase
        research_output = research_agent.invoke(target=target, requirements=requirements)
        write_checkpoint(target.id, "research", research_output)
        agent_observable.emit(AgentEvent.RESEARCH_COMPLETE, target.id, 
                            {"requirements_count": len(requirements)})
        
        # Assessment phase
        assessment_output = assessment_agent.invoke(
            research_data=research_output,
            criteria=requirements.assessment_criteria
        )
        write_checkpoint(target.id, "assessment", assessment_output)
        agent_observable.emit(AgentEvent.ASSESSMENT_COMPLETE, target.id,
                            {"score": assessment_output.total_score})
        
        # Report generation phase
        report = report_agent.invoke(assessment_data=assessment_output)
        write_checkpoint(target.id, "report", report)
        agent_observable.emit(AgentEvent.REPORT_COMPLETE, target.id)
        
        return report
        
    except Exception as e:
        agent_observable.emit(AgentEvent.FAILED, target.id, {"error": str(e)})
        raise
```

The TUI subscribed to these events and updated the display in real-time using the `rich` library - progress bars for each phase, a live table showing target status, and a scrolling log of events.

Watching 200 targets flow through the pipeline simultaneously, seeing progress bars update as research completed, assessment scores populate, and reports generate - that was the moment it felt real. Not just a script running in the background, but a system you could observe and understand. When a target failed, I could see exactly which phase it was in and what the last successful event was.

## Retry Logic

At 200 targets with multiple API calls per target, something will fail. I built retry logic with exponential backoff and differentiated between retryable errors (rate limits, timeouts, 5xx) and hard failures (invalid API keys, 4xx). A transient network blip doesn't kill the entire 4-hour run.

## What's Next

The current system works, but there's an obvious gap: assessment can't feed back into research. If the assessment agent realizes it doesn't have enough information to score a requirement, it just works with what it has.

The roadmap item is making research callable from assessment - a tool that assessment can invoke with a focused definition targeting just one requirement. Assessment realizes it needs more data, calls research with a specific query, gets the additional context, continues scoring. Turns the linear pipeline into a feedback loop.

## What I Learned

Parse your configuration yourself instead of hoping the LLM understands it. One agent per responsibility makes debugging possible. Don't use framework features you don't need - if your workflow is fixed, orchestrate it yourself. Write intermediate results to disk for the audit trail. Parallelize at the highest level first. Build observability into the system with an observable pattern - real-time visibility into agent execution is worth the extra code. Build retry logic from the start with exponential backoff and error differentiation. Estimate costs before big runs. A good TUI makes complex systems understandable when you're running hundreds of parallel operations.

## Where It Landed

The system processes research targets in parallel, outputs structured JSON for visualization tools, and handles failures gracefully. The TUI provides real-time visibility into hundreds of concurrent operations. The YAML-defined requirements make it flexible enough to adapt to new research criteria without rebuilding agents. The observable pattern makes it debuggable when things go wrong.

What started as "I need structured output for visualizations" turned into learning about agent orchestration, API economics, real-time observability patterns, and the difference between framework features and actual requirements.

Would I do it again? Absolutely. Would I recommend it to everyone? Not a chance. But if you're building research pipelines that need to scale and adapt to changing requirements, this architecture works.

Just buy enough API credits before the 200-target run. And build the TUI early - watching your agents work in real-time is worth it.

---

*Published: December 15, 2025*
