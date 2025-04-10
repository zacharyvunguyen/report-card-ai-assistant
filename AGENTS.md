# Report Card Analysis System: Agent Architecture

## Overview

The **Report Card Analysis System** uses a **sequential multi-agent architecture** to transform elementary school report cards into structured, actionable insights. Each agent has a specialized responsibility and builds upon the output of the previous agent, forming a cohesive analysis pipeline.

---

## Agent Workflow

The agents operate in a fixed sequence:

```
OverviewAgent → WeaknessAgent → ResearchAgent → StudyPlanAgent → ReportAgent
```

Each agent uses specific tools to process, analyze, and store results.

---

## Agent Responsibilities & Tools

### 1. OverviewAgent
**Purpose**: Analyze the student's overall academic and behavioral performance.  
**Outputs**: Performance summary, strengths, learning patterns.  
**Tools**:
- `query_engine_tool`: Retrieves context from the index.
- `record_analysis`: Saves summary to memory.

**Next**: Hands off to **WeaknessAgent**

---

### 2. WeaknessAgent  
**Purpose**: Identify subjects and standards with lower scores (≤ 2).  
**Outputs**: Prioritized list of weaknesses by subject.  
**Tools**:
- `weakness_tool`: Filters weak areas.
- `subject_tool`: Analyzes by academic standards.
- `record_analysis`: Stores findings.

**Next**: Hands off to **ResearchAgent**

---

### 3. ResearchAgent  
**Purpose**: Recommend learning resources and strategies.  
**Outputs**: Resource list with actionable strategies.  
**Tools**:
- `TavilyToolSpec` (via `search_web`): Web search for evidence-based materials.
- `record_analysis`: Logs findings.

**Next**: Hands off to **StudyPlanAgent**

---

### 4. StudyPlanAgent  
**Purpose**: Create a customized study plan based on identified weaknesses and suggested strategies.  
**Outputs**: Weekly learning goals, suggested activities, tracking methods.  
**Tools**:
- `create_study_plan`: Builds structured plan.
- `record_analysis`: Saves the generated plan.

**Next**: Hands off to **ReportAgent**

---

### 5. ReportAgent  
**Purpose**: Compile all prior agent outputs into a professional final report.  
**Outputs**: Executive summary, complete analysis, next steps.  
**Tools**:
- `compile_report`: Synthesizes all analyses.
- `record_analysis`: Logs final content.
- `ReportLab`: Generates PDF.

**Final Agent**: Outputs final report to UI.

---

## Execution & Workflow

### Orchestration

The agent sequence is managed by `AgentWorkflow`, which:
- Tracks execution order
- Prevents redundancy
- Generates continuation prompts for each agent

```python
workflow = AgentWorkflow(
  agents=[overview_agent, weakness_agent, research_agent, study_plan_agent, report_agent],
  root_agent="OverviewAgent",
  initial_state={...}
)
```

### Automatic Prompt Chaining

If user prompts are vague, the system triggers continuation prompts:

```python
continuation_prompt = "Analyze the report card to identify areas needing improvement."
```

---

## Technical Stack

| Component       | Value                         |
|----------------|-------------------------------|
| Python Version  | `3.13.2`                      |
| Embedding Model | `text-embedding-3-large` (OpenAI) |
| LLM Model       | `gpt-4o` |
| Chunking        | 2048 tokens w/ 128 overlap    |
| Temperature     | 0.2 (for reliable output)     |
| Query Modes     | `tree_summarize`, `accumulate`|

---

## Query Engine Configurations

| Agent         | Mode           | Top-K | Purpose                              |
|---------------|----------------|-------|--------------------------------------|
| Overview      | tree_summarize | 200   | High-level performance summary       |
| Weakness      | accumulate     | 150   | Issue-focused data extraction        |
| Subject       | tree_summarize | 150   | In-depth subject-specific breakdown  |

---

## Streamlit UI Integration

- **Dynamic Tabs**: One per agent, with live status.
- **Tool Display**: Shows which tools each agent used.
- **PDF Generation**: Individual and full-report downloads.
- **Timestamps**: Every output includes generation time.

---

## Logging & Monitoring

Logged with timestamps for:
- Agent transitions
- Tool usage
- API interactions
- Errors and fallbacks

---

## Best Practices

1. **Use Specific Prompts** for focused results.
2. **Let the Workflow Complete** to unlock all insights.
3. **Review Each Agent Tab** for unique contributions.
4. **Download the Combined PDF** for a polished report.
5. **Check Tool Traces** to validate analysis paths.

---

## Future Enhancements

- Parallel agent execution (where possible)
- Configurable workflows per user type
- Interactive study plans with live tracking
- Visualization for student progress trends
- Agent-to-agent feedback loops

