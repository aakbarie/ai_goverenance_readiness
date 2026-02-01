# How to Use the AI Governance Assessment Tool

This guide walks you through the complete assessment workflow, from initial evaluation to generating action plans and reports.

---

## Quick Start

1. **Review the Dashboard** - Get an overview of your current governance maturity
2. **Complete the Assessment** - Rate each governance domain (GOV 1-8)
3. **Analyze Gaps** - Review the gap analysis to identify priority areas
4. **Generate Recommendations** - Use AI-powered insights for improvement guidance
5. **Create Action Plan** - Build a prioritized roadmap for governance improvements
6. **Export Reports** - Generate documentation for stakeholders

---

## Step 1: Understanding the Dashboard

The **Dashboard** provides an at-a-glance view of your governance posture:

### Key Metrics
- **Overall Maturity Score** - Aggregate score across all domains (0-4 scale)
- **Questions Assessed** - Progress tracking for assessment completion
- **Critical/High Gaps** - Number of areas requiring immediate attention
- **Assessment Cycle** - Current assessment period and last update

### Visual Analytics
- **Radar Chart** - Domain maturity visualization across all 8 governance areas
- **Comparison Chart** - Current vs. target maturity by domain
- **Gap Waterfall** - Visual representation of gaps by domain
- **Priority Distribution** - Breakdown of action items by priority level

---

## Step 2: Completing the Assessment

Navigate through each governance domain (GOV 1-8) using the sidebar menu or the navigation buttons at the bottom of each section.

### For Each Question

1. **Read the Assessment Question** - The main question to evaluate
2. **Review the Description** - Detailed context including healthcare-specific considerations
3. **Select Current Maturity Level** - Rate where your organization is today
4. **Select Target Maturity Level** - Define where you want to be

### Maturity Level Definitions

| Level | Name | Description |
|-------|------|-------------|
| **0** | Absent | No capability exists |
| **1** | Initial/Ad hoc | Informal, reactive processes |
| **2** | Defined | Documented policies and procedures |
| **3** | Repeatable | Consistent, measured processes |
| **4** | Managed/Optimized | Continuous improvement, metrics-driven |

### Assessment Tips

- **Be honest** - Accurate assessment leads to meaningful improvement plans
- **Gather input** - Consult with compliance, IT, legal, and clinical stakeholders
- **Document evidence** - Note specific examples supporting your ratings
- **Consider consistency** - Ensure ratings reflect organization-wide practices, not exceptions

---

## Step 3: Reviewing Gap Analysis

After completing the assessment, navigate to the **Gap Analysis** tab to understand your improvement opportunities.

### Gap Calculation
The gap is calculated as: **Target Level - Current Level**

### Priority Classification

| Priority | Gap Size | Current Level | Action Required |
|----------|----------|---------------|-----------------|
| **Critical** | 3+ levels | Any | Immediate action required |
| **Critical** | 2+ levels | 0-1 | Urgent attention needed |
| **High** | 2 levels | 2+ | Address in near-term |
| **Medium** | 1 level | Any | Plan for improvement |
| **Low** | 0 levels | Any | Maintain current state |

### Using the Gap Analysis

1. Focus first on **Critical** and **High** priority items
2. Consider dependencies between governance areas
3. Identify quick wins (high benefit, low effort)
4. Plan for foundational improvements that enable other enhancements

---

## Step 4: Generating AI Recommendations

The **Action Plan** tab includes AI-powered recommendation generation.

### Configuring the LLM Connection

1. **Select Provider** - Choose llama.cpp, Ollama, or OpenAI
2. **Configure Server URL** - Set the appropriate endpoint
   - llama.cpp: `http://localhost:8080` (default)
   - Ollama: `http://localhost:11434` (default)
   - OpenAI: Uses API key
3. **Test Connection** - Verify the LLM server is accessible
4. **Generate Recommendations** - Click to receive AI-generated insights

### LLM Setup Options

#### Option A: llama.cpp (Recommended for Privacy)
```bash
# Start the server with your GGUF model
./llama-server -m /path/to/model.gguf --port 8080
```

#### Option B: Ollama (Easy Setup)
```bash
# Start Ollama and pull a model
ollama serve
ollama pull llama3.1:8b
```

#### Option C: OpenAI (Cloud-based)
- Set the `OPENAI_API_KEY` environment variable
- Or enter your API key in the settings panel

### Understanding AI Recommendations

The AI provides:
- **Gap-specific recommendations** tailored to your assessment results
- **Healthcare compliance considerations** relevant to payor organizations
- **Implementation guidance** with practical steps
- **Risk mitigation strategies** for identified weaknesses

---

## Step 5: Creating the Action Plan

Build your governance improvement roadmap using the Action Plan features.

### Priority Matrix

Use the benefit-effort analysis to prioritize actions:

| Benefit / Effort | High Effort | Low Effort |
|------------------|-------------|------------|
| **High Benefit** | Strategic | Quick Wins |
| **Low Benefit** | Avoid | Fill-ins |

### Setting Action Items

For each gap identified:
1. **Assign benefit level** - Expected impact on governance maturity
2. **Assign effort level** - Resources and time required
3. **Add notes** - Document specific implementation considerations
4. **Set ownership** - Identify responsible parties (outside the tool)

### Prioritization Strategy

1. **Quick Wins First** - High benefit, low effort items build momentum
2. **Strategic Investments** - High benefit, high effort items for significant improvement
3. **Foundational Items** - Some high-effort items may be prerequisites for others
4. **Avoid Low-Value Items** - Low benefit, high effort items should be deprioritized

---

## Step 6: Exporting Reports

Navigate to the **Reports** tab to generate documentation.

### Available Reports

- **Executive Summary** - High-level maturity overview for leadership
- **Detailed Assessment** - Complete assessment results with all ratings
- **Gap Analysis Report** - Prioritized gaps with recommendations
- **Action Plan Export** - Implementation roadmap with priorities

### Report Formats

- **Excel (.xlsx)** - Detailed data export for further analysis
- **Dashboard View** - On-screen summary for presentations

### Report Uses

- Board and executive presentations
- Regulatory audit documentation
- Compliance reporting
- Vendor and partner assessments
- Annual governance reviews

---

## Best Practices

### Assessment Frequency

- **Initial Assessment** - Comprehensive baseline evaluation
- **Quarterly Reviews** - Monitor progress and update ratings
- **Annual Deep Dive** - Full reassessment with stakeholder input
- **Trigger-Based Updates** - Reassess after significant changes

### Stakeholder Involvement

Engage these key stakeholders in the assessment process:

- **Compliance/Legal** - Regulatory requirements and risk tolerance
- **Information Security** - Technical controls and data protection
- **IT/Data Governance** - System inventory and lifecycle management
- **Clinical/Operations** - Member impact and workflow considerations
- **Executive Leadership** - Strategic priorities and resource allocation

### Continuous Improvement

1. **Track trends** - Monitor maturity progression over time
2. **Celebrate progress** - Recognize improvements achieved
3. **Learn from incidents** - Update assessments after AI-related events
4. **Stay current** - Incorporate regulatory updates and industry guidance

---

## Troubleshooting

### Common Issues

**Assessment not saving**
- Use the "Save Progress" button in the sidebar
- Check browser console for errors

**LLM connection failed**
- Verify the server is running: `curl http://localhost:8080/health`
- Check the server URL matches your configuration
- Ensure no firewall is blocking the connection

**Charts not displaying**
- Refresh the browser
- Complete at least one assessment question

**Export not working**
- Ensure the `openxlsx` package is installed
- Check write permissions in the download directory

---

## Additional Resources

- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)
- [NIST AI RMF Playbook](https://airc.nist.gov/AI_RMF_Knowledge_Base/Playbook)
- [HHS AI Strategy](https://www.hhs.gov/ai)

---

*For technical support or feature requests, please contact your system administrator.*
