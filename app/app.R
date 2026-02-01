# =============================================================================
# AI GOVERNANCE ASSESSMENT TOOL
# Continuous Recursive Governance Assessment Platform
# =============================================================================
# Built on NIST AI RMF framework aligned with organizational governance policies
# Supports tiered governance (Tier 0-3), vendor AI oversight, and member safety
# =============================================================================

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(DT)
library(plotly)
library(dplyr)
library(tidyr)
library(httr)
library(jsonlite)
library(openxlsx)
library(markdown)

# ellmer package for LLM integration (supports Ollama, OpenAI, etc.)
# Install with: install.packages("ellmer")
if (!requireNamespace("ellmer", quietly = TRUE)) {
  message("ellmer package not installed. LLM features will use fallback mode.")
  message("Install with: install.packages('ellmer')")
  ELLMER_AVAILABLE <- FALSE
} else {
  library(ellmer)
  ELLMER_AVAILABLE <- TRUE
}

# =============================================================================
# LLM CONFIGURATION
# =============================================================================

# Default LLM settings
DEFAULT_LLM_PROVIDER <- "llama_cpp"  # "llama_cpp", "ollama", or "openai"
DEFAULT_LLAMA_CPP_MODEL <- "local-model"  # Display name for llama.cpp model
DEFAULT_OLLAMA_MODEL <- "llama3.1:8b"
DEFAULT_OPENAI_MODEL <- "gpt-4"
LLAMA_CPP_BASE_URL <- "http://localhost:8080"  # Default llama.cpp server (llama-server)
OLLAMA_BASE_URL <- "http://localhost:11434"  # Default Ollama server

# System prompt for AI governance recommendations
SYSTEM_PROMPT <- "You are an expert AI governance consultant specializing in NIST AI RMF, healthcare compliance (HIPAA, CMIA, CPRA/CCPA), and organizational risk management. You help organizations improve their AI governance maturity. Provide concise, actionable recommendations that are specific and implementable."

# =============================================================================
# GOVERNANCE FRAMEWORK CONFIGURATION
# =============================================================================

# Maturity levels aligned with NIST AI RMF
maturity_levels <- c(
  
  "0 - Absent" = 0,
  "1 - Initial/Ad hoc" = 1,
  "2 - Defined" = 2,
  "3 - Repeatable" = 3,
  "4 - Managed/Optimized" = 4
)

level_choices <- names(maturity_levels)

# Priority/Effort matrix for action items
benefit_choices <- c(
  "0 - Minimal Benefit" = 0,
  "1 - Moderate Benefit" = 1,
  "2 - Significant Benefit" = 2
)

effort_choices <- c(
  "0 - Significant Effort" = 0,
  "1 - Moderate Effort" = 1,
  "2 - Minimal Effort" = 2
)

# =============================================================================
# GOVERNANCE ASSESSMENT FRAMEWORK
# Aligned with NIST AI RMF GOVERN Function + Organizational Policy Requirements
# =============================================================================

# --- GOV 1: Governance Policies & Procedures ---
gov_section1 <- data.frame(
  Code = c("GOV 1.1", "GOV 1.2", "GOV 1.3", "GOV 1.4", "GOV 1.5", "GOV 1.6", "GOV 1.7"),
  Assessment_Question = c(
    "Legal and regulatory requirements involving AI are understood, managed, and documented.",
    "Responsible AI principles are documented and integrated into organizational policies.",
    "Processes are in place to determine needed risk management activities based on organizational risk tolerance.",
    "Risk management process outcomes are established through transparent policies and controls.",
    "Risk management process is monitored and reviewed periodically with defined roles and frequencies.",
    "Mechanisms are in place and resourced to maintain an inventory of AI systems.",
    "Processes exist for safe decommissioning of AI systems aligned with risk tolerance."
  ),
  Description = c(
    "We have identified, understood, managed, and documented legal and regulatory requirements involving AI in the jurisdictions and industries where we operate, including HIPAA, CMIA, CPRA/CCPA compliance.",
    "We have documented responsible AI principles (fairness, transparency, accountability, privacy, security) integrated into organizational policies and the AI lifecycle.",
    "We have established processes, procedures, and practices to determine the needed level of risk management activities based on the organization's risk tolerance, including tiered governance (Tier 0-3).",
    "We have established a risk management process with outcomes documented through transparent policies, procedures, and controls based on organizational risk priorities.",
    "We monitor and periodically review our risk management process. Review outcomes and frequency are planned, and organizational roles and responsibilities are clearly defined.",
    "We have a sufficiently resourced mechanism to inventory AI systems, track governance tier classifications, approvals, and compliance status.",
    "We have necessary processes and procedures for decommissioning and phasing out AI systems safely and in line with our risk tolerance, including data deletion and vendor exit plans."
  ),
  Default_Current = c(3, 1, 2, 2, 2, 2, 1),
  Default_Target = c(4, 4, 4, 4, 4, 3, 3),
  stringsAsFactors = FALSE
)

# --- GOV 2: Accountability & Roles ---
gov_section2 <- data.frame(
  Code = c("GOV 2.1", "GOV 2.2", "GOV 2.3"),
  Assessment_Question = c(
    "Roles, responsibilities, and communication lines for AI risk management are documented and understood.",
    "Personnel and partners receive AI risk management training aligned with policies.",
    "Executive leadership takes responsibility for decisions about material AI risks."
  ),
  Description = c(
    "We have documented roles and responsibilities and lines of communication related to mapping, measuring, and managing AI risks. These roles are clearly understood by people assigned to those roles, including AI Governance Committee membership.",
    "Our organization's personnel and partners receive AI risk management training to enable them to perform their duties consistent with related policies, procedures, and agreements. Training includes prohibited uses, tier requirements, and attestation.",
    "Executive leadership (CIO, CCO) takes responsibility for decisions about material AI risks, including escalation authority for Tier C/D systems and regulatory implications."
  ),
  Default_Current = c(1, 0, 1),
  Default_Target = c(3, 3, 4),
  stringsAsFactors = FALSE
)

# --- GOV 3: Human Oversight & Decision-Making ---
gov_section3 <- data.frame(
  Code = c("GOV 3.1", "GOV 3.2", "GOV 3.3"),
  Assessment_Question = c(
    "Decision-making is informed by diverse teams providing multiple perspectives.",
    "Human-in-the-loop oversight processes are defined for AI systems.",
    "Override and escalation mechanisms are established for AI-assisted decisions."
  ),
  Description = c(
    "Decision-making is informed by a diverse team (compliance, legal, clinical, IT, data governance, security, privacy) to provide multiple perspectives for AI risk management through the AI Governance Committee.",
    "We have defined roles, responsibilities, practices, and processes for human-in-the-loop oversight of AI systems. AI may support but not replace human judgment for member-impacting decisions.",
    "Staff have clear override authority and escalation pathways. Any denial/delay/modification workflow meets applicable human review requirements. AI-generated content is not 'policy' unless formally approved."
  ),
  Default_Current = c(1, 1, 1),
  Default_Target = c(3, 4, 4),
  stringsAsFactors = FALSE
)

# --- GOV 4: Culture & Communication ---
gov_section4 <- data.frame(
  Code = c("GOV 4.1", "GOV 4.2", "GOV 4.3"),
  Assessment_Question = c(
    "Policies foster a critical thinking and safety-first mindset in AI design and deployment.",
    "Teams document and communicate the risks and impacts of AI technology they use.",
    "Practices are in place for AI testing, incident identification, and information sharing."
  ),
  Description = c(
    "Our policies foster a critical thinking and safety-first mindset in AI design and deployment, ensuring ethical, unbiased, and legally compliant AI use with fairness/bias assessment for member-impacting workflows.",
    "Teams document and communicate the risks and impacts of the AI technology they use, including output disclaimers, usage limitations, and risk assessments for each governance tier.",
    "We have practices in place for AI testing, incident identification, and information sharing, including incident response protocols, root cause analysis, and corrective actions for AI-related events."
  ),
  Default_Current = c(1, 0, 1),
  Default_Target = c(3, 4, 4),
  stringsAsFactors = FALSE
)

# --- GOV 5: External Feedback & Stakeholder Engagement ---
gov_section5 <- data.frame(
  Code = c("GOV 5.1", "GOV 5.2"),
  Assessment_Question = c(
    "Policies exist to collect, consider, and integrate external feedback regarding AI risks.",
    "Mechanisms regularly incorporate adjudicated feedback from relevant AI actors."
  ),
  Description = c(
    "Organizational policies and practices are in place to collect, consider, prioritize, and integrate feedback from those external to the team(s) that developed or deployed AI systems regarding potential individual and societal impacts.",
    "Mechanisms are established to enable regular incorporation of adjudicated feedback from relevant AI actors (members, providers, regulators, vendors) into system design and implementation."
  ),
  Default_Current = c(0, 1),
  Default_Target = c(3, 3),
  stringsAsFactors = FALSE
)

# --- GOV 6: Third-Party & Vendor Risk ---
gov_section6 <- data.frame(
  Code = c("GOV 6.1", "GOV 6.2", "GOV 6.3"),
  Assessment_Question = c(
    "Policies address AI risks related to third-party entities and vendors.",
    "Contingency processes handle failures in third-party AI systems.",
    "Vendor AI disclosures and contractual controls are enforced."
  ),
  Description = c(
    "We have policies addressing AI risks related to third-party entities, including vendor AI evaluation in procurement, BAA requirements, no-training clauses, data retention controls, and SOC 2 Type II attestation.",
    "We have contingency processes to handle failures or incidents in high-risk third-party data or AI systems, including exit plans and ability to revoke access and delete data.",
    "All vendors disclose use of AI-enabled systems. Execution of a BAA does not substitute for AI Governance Committee approval. Third-party AI systems are subject to the same tier classification and monitoring requirements."
  ),
  Default_Current = c(1, 0, 1),
  Default_Target = c(3, 3, 3),
  stringsAsFactors = FALSE
)

# --- GOV 7: AI System Lifecycle & Tiered Governance ---
gov_section7 <- data.frame(
  Code = c("GOV 7.1", "GOV 7.2", "GOV 7.3", "GOV 7.4"),
  Assessment_Question = c(
    "AI systems are classified into governance tiers based on operational impact.",
    "Tier-appropriate controls and documentation are required before deployment.",
    "Ongoing monitoring and periodic recertification are enforced for production AI.",
    "Change management triggers re-review and potential re-tiering."
  ),
  Description = c(
    "All AI-enabled systems are classified into governance tiers (Tier 0: Exploratory, Tier 1: Internal Decision Support, Tier 2: Operational/Member-Impacting, Tier 3: High-Risk/Regulated Automation) based on operational impact, not intent or architecture.",
    "Based on proposed tier, AI Governance Committee confirms classification, reviews required control elements, and approves/conditions/defers/denies use. No Tier 2/3 system moves to production without recorded approval.",
    "Tier 2 and Tier 3 systems are subject to ongoing monitoring and periodic reporting including performance drift, bias/fairness concerns, incidents, vendor changes, and model updates.",
    "Changes in data types, functionality, member impact, vendor/model updates, or applicable laws trigger re-review and potential re-tiering by the AI Governance Committee."
  ),
  Default_Current = c(2, 1, 1, 1),
  Default_Target = c(4, 4, 4, 4),
  stringsAsFactors = FALSE
)

# --- GOV 8: Privacy, Security & Compliance ---
gov_section8 <- data.frame(
  Code = c("GOV 8.1", "GOV 8.2", "GOV 8.3"),
  Assessment_Question = c(
    "AI systems comply with HIPAA, CMIA, and applicable privacy regulations.",
    "Security controls (encryption, logging, least privilege) are enforced for AI systems.",
    "PHI/PII boundaries and prohibited uses are clearly defined and enforced."
  ),
  Description = c(
    "AI use aligns with HIPAA, CMIA, CPRA/CCPA and internal policies. PHI/PII disclosure requirements and prohibited uses are defined and enforced. Documentation completeness is validated for audits and regulatory inquiries.",
    "AI systems are reviewed for security risks with required controls enforced (least privilege, encryption, logging). Incident response expectations for AI-related events (data exposure, misuse, leakage) are defined.",
    "Staff are prohibited from inputting PHI/PII into AI systems without an executed BAA. Sensitive data boundaries, disclosure requirements, and staff attestation requirements are defined and enforced."
  ),
  Default_Current = c(2, 2, 1),
  Default_Target = c(4, 4, 4),
  stringsAsFactors = FALSE
)

# Combine all sections for reference
all_sections <- list(
  "GOV 1: Policies & Procedures" = gov_section1,
  "GOV 2: Accountability & Roles" = gov_section2,
  "GOV 3: Human Oversight" = gov_section3,
  "GOV 4: Culture & Communication" = gov_section4,
  "GOV 5: External Feedback" = gov_section5,
  "GOV 6: Third-Party Risk" = gov_section6,
  "GOV 7: Lifecycle & Tiered Governance" = gov_section7,
  "GOV 8: Privacy & Security" = gov_section8
)

# Section metadata for navigation
section_info <- data.frame(
  id = c("gov1", "gov2", "gov3", "gov4", "gov5", "gov6", "gov7", "gov8"),
  title = c(
    "Policies & Procedures",
    "Accountability & Roles",
    "Human Oversight",
    "Culture & Communication",
    "External Feedback",
    "Third-Party Risk",
    "Lifecycle & Tiered Governance",
    "Privacy & Security"
  ),
  icon = c("file-contract", "users-cog", "user-shield", "comments", "bullhorn", "handshake", "project-diagram", "lock"),
  color = c("blue", "green", "purple", "orange", "teal", "maroon", "navy", "red"),
  stringsAsFactors = FALSE
)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Convert level string to numeric
level_to_num <- function(level_str) {
  if (is.null(level_str) || level_str == "" || is.na(level_str)) return(NA)
  as.numeric(sub(" -.*", "", level_str))
}

# Convert numeric to level string
num_to_level <- function(num) {
  if (is.null(num) || is.na(num)) return("0 - Absent")
  level_choices[num + 1]
}

# Calculate priority based on gap and current score
calculate_priority <- function(gap, current_score) {
  if (is.na(gap) || is.na(current_score)) return("Low")
  if (gap >= 3 || (gap >= 2 && current_score <= 1)) return("Critical")
  if (gap >= 2) return("High")
  if (gap >= 1) return("Medium")
  return("Low")
}

# Color mapping for maturity levels
get_level_color <- function(level) {
  num <- level_to_num(level)
  if (is.na(num)) return("#dc3545")
  colors <- c("#dc3545", "#fd7e14", "#ffc107", "#28a745", "#17a2b8")
  colors[num + 1]
}

# =============================================================================
# UI DEFINITION
# =============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = tags$span(
      tags$img(src = "", height = "30px", style = "margin-right: 10px;"),
      "AI Governance Assessment"
    ),
    titleWidth = 320
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 320,
    sidebarMenu(
      id = "sidebar_menu",

      # Main Navigation
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("How-To Guide", tabName = "howto", icon = icon("book")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("tachometer-alt")),
      menuItem("Assessment", tabName = "assessment", icon = icon("clipboard-check"),
               startExpanded = TRUE,
               menuSubItem("GOV 1: Policies", tabName = "gov1", icon = icon("file-contract")),
               menuSubItem("GOV 2: Accountability", tabName = "gov2", icon = icon("users-cog")),
               menuSubItem("GOV 3: Human Oversight", tabName = "gov3", icon = icon("user-shield")),
               menuSubItem("GOV 4: Culture", tabName = "gov4", icon = icon("comments")),
               menuSubItem("GOV 5: External Feedback", tabName = "gov5", icon = icon("bullhorn")),
               menuSubItem("GOV 6: Third-Party Risk", tabName = "gov6", icon = icon("handshake")),
               menuSubItem("GOV 7: Lifecycle", tabName = "gov7", icon = icon("project-diagram")),
               menuSubItem("GOV 8: Privacy & Security", tabName = "gov8", icon = icon("lock"))
      ),
      menuItem("Gap Analysis", tabName = "gap_analysis", icon = icon("chart-bar")),
      menuItem("Action Plan", tabName = "action_plan", icon = icon("tasks")),
      menuItem("Reports", tabName = "reports", icon = icon("file-export"))
    ),

    hr(),

    # Assessment Info
    div(
      class = "sidebar-section sidebar-status",
      h5("Assessment Status", style = "color: #fff; margin-bottom: 10px;"),
      uiOutput("sidebar_status")
    ),

    hr(),

    # Quick Actions
    div(
      class = "sidebar-section sidebar-actions",
      actionButton("save_assessment", "Save Progress",
                   icon = icon("save"),
                   class = "btn-success btn-block"),
      actionButton("generate_ai_recommendations", "Generate AI Insights",
                   icon = icon("robot"),
                   class = "btn-info btn-block")
    )
  ),
  
  # Body
  dashboardBody(
    # External CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    
    tabItems(
      # =========================================================================
      # HOME TAB
      # =========================================================================
      tabItem(
        tabName = "home",
        fluidRow(
          column(12,
                 div(class = "markdown-content",
                     style = "background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.08);",
                     uiOutput("home_content")
                 )
          )
        )
      ),

      # =========================================================================
      # HOW-TO TAB
      # =========================================================================
      tabItem(
        tabName = "howto",
        fluidRow(
          column(12,
                 div(class = "markdown-content",
                     style = "background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.08);",
                     uiOutput("howto_content")
                 )
          )
        )
      ),

      # =========================================================================
      # DASHBOARD TAB
      # =========================================================================
      tabItem(
        tabName = "dashboard",
        
        # Header Row
        fluidRow(
          column(12,
                 div(class = "section-header",
                     h3(icon("tachometer-alt"), " AI Governance Dashboard"),
                     p("Continuous assessment and monitoring of organizational AI governance maturity")
                 )
          )
        ),
        
        # Score Cards Row
        fluidRow(
          column(3,
                 div(class = "score-card",
                     div(class = "score-value", style = "color: #3c8dbc;",
                         textOutput("overall_score_text", inline = TRUE)),
                     div(class = "score-label", "Overall Maturity Score"),
                     div(style = "margin-top: 15px;",
                         tags$small("Target: 4.0 | Max: 4.0"))
                 )
          ),
          column(3,
                 div(class = "score-card",
                     div(class = "score-value", style = "color: #28a745;",
                         textOutput("completed_count", inline = TRUE)),
                     div(class = "score-label", "Questions Assessed"),
                     div(style = "margin-top: 15px;",
                         tags$small(textOutput("total_questions", inline = TRUE), " total"))
                 )
          ),
          column(3,
                 div(class = "score-card",
                     div(class = "score-value", style = "color: #dc3545;",
                         textOutput("critical_gaps", inline = TRUE)),
                     div(class = "score-label", "Critical/High Gaps"),
                     div(style = "margin-top: 15px;",
                         tags$small("Requiring immediate attention"))
                 )
          ),
          column(3,
                 div(class = "score-card",
                     div(class = "score-value", style = "color: #17a2b8;",
                         textOutput("assessment_cycle", inline = TRUE)),
                     div(class = "score-label", "Assessment Cycle"),
                     div(style = "margin-top: 15px;",
                         tags$small(textOutput("last_updated", inline = TRUE)))
                 )
          )
        ),
        
        br(),
        
        # Charts Row
        fluidRow(
          box(
            title = "Governance Domain Maturity",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 450,
            plotlyOutput("radar_chart", height = "380px")
          ),
          box(
            title = "Current vs Target by Domain",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 450,
            plotlyOutput("domain_comparison_chart", height = "380px")
          )
        ),
        
        # Gap Analysis Row
        fluidRow(
          box(
            title = "Gap Analysis Overview",
            status = "warning",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("gap_waterfall", height = "300px")
          ),
          box(
            title = "Priority Distribution",
            status = "danger",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("priority_pie", height = "300px")
          )
        ),
        
        # Quick Action Items
        fluidRow(
          box(
            title = "Top Priority Actions",
            status = "danger",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            uiOutput("top_actions_dashboard")
          )
        )
      ),
      
      # =========================================================================
      # ASSESSMENT TABS (GOV 1-8)
      # =========================================================================
      
      # GOV 1: Policies & Procedures
      tabItem(
        tabName = "gov1",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #3c8dbc 0%, #2c6e8e 100%);",
                     h3(icon("file-contract"), " GOV 1: Governance Policies & Procedures"),
                     p("Legal compliance, risk management processes, and AI system inventory")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov1_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov2", "Continue to GOV 2: Accountability",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 2: Accountability & Roles
      tabItem(
        tabName = "gov2",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #28a745 0%, #1e7e34 100%);",
                     h3(icon("users-cog"), " GOV 2: Accountability & Roles"),
                     p("Roles, responsibilities, training, and executive leadership accountability")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov2_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov1_from_2", "Back to GOV 1",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov3", "Continue to GOV 3: Human Oversight",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 3: Human Oversight
      tabItem(
        tabName = "gov3",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #6f42c1 0%, #5a32a3 100%);",
                     h3(icon("user-shield"), " GOV 3: Human Oversight & Decision-Making"),
                     p("Diverse teams, human-in-the-loop processes, and override mechanisms")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov3_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov2_from_3", "Back to GOV 2",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov4", "Continue to GOV 4: Culture",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 4: Culture & Communication
      tabItem(
        tabName = "gov4",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #fd7e14 0%, #dc6a00 100%);",
                     h3(icon("comments"), " GOV 4: Culture & Communication"),
                     p("Safety-first mindset, risk documentation, and incident management")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov4_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov3_from_4", "Back to GOV 3",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov5", "Continue to GOV 5: External Feedback",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 5: External Feedback
      tabItem(
        tabName = "gov5",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #20c997 0%, #17a085 100%);",
                     h3(icon("bullhorn"), " GOV 5: External Feedback & Stakeholder Engagement"),
                     p("External feedback collection and integration mechanisms")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov5_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov4_from_5", "Back to GOV 4",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov6", "Continue to GOV 6: Third-Party Risk",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 6: Third-Party Risk
      tabItem(
        tabName = "gov6",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #6c757d 0%, #545b62 100%);",
                     h3(icon("handshake"), " GOV 6: Third-Party & Vendor Risk"),
                     p("Vendor AI policies, contingency processes, and contractual controls")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov6_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov5_from_6", "Back to GOV 5",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov7", "Continue to GOV 7: Lifecycle",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 7: Lifecycle & Tiered Governance
      tabItem(
        tabName = "gov7",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #001f3f 0%, #003366 100%);",
                     h3(icon("project-diagram"), " GOV 7: AI System Lifecycle & Tiered Governance"),
                     p("Tier classification, deployment controls, monitoring, and change management")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov7_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov6_from_7", "Back to GOV 6",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("nav_to_gov8", "Continue to GOV 8: Privacy & Security",
                                  icon = icon("arrow-right"), class = "btn-primary btn-lg")
                 )
          )
        )
      ),

      # GOV 8: Privacy & Security
      tabItem(
        tabName = "gov8",
        fluidRow(
          column(12,
                 div(class = "section-header", style = "background: linear-gradient(135deg, #dc3545 0%, #bd2130 100%);",
                     h3(icon("lock"), " GOV 8: Privacy, Security & Compliance"),
                     p("HIPAA/regulatory compliance, security controls, and PHI/PII protections")
                 )
          )
        ),
        fluidRow(
          column(12,
                 uiOutput("gov8_questions")
          )
        ),
        fluidRow(
          column(12,
                 div(class = "nav-buttons",
                     actionButton("nav_to_gov7_from_8", "Back to GOV 7",
                                  icon = icon("arrow-left"), class = "btn-default btn-lg"),
                     actionButton("complete_assessment", "Complete Assessment",
                                  icon = icon("check-circle"), class = "btn-success btn-lg")
                 )
          )
        )
      ),

      # =========================================================================
      # GAP ANALYSIS TAB
      # =========================================================================
      tabItem(
        tabName = "gap_analysis",
        fluidRow(
          column(12,
                 div(class = "section-header",
                     h3(icon("chart-bar"), " Gap Analysis"),
                     p("Detailed analysis of governance maturity gaps and improvement opportunities")
                 )
          )
        ),
        fluidRow(
          box(
            title = "Gap Analysis by Domain",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("detailed_gap_chart", height = "400px")
          )
        ),
        fluidRow(
          box(
            title = "Detailed Assessment Results",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("gap_analysis_table")
          )
        )
      ),
      
      # =========================================================================
      # ACTION PLAN TAB
      # =========================================================================
      tabItem(
        tabName = "action_plan",
        fluidRow(
          column(12,
                 div(class = "section-header",
                     h3(icon("tasks"), " Action Plan"),
                     p("Prioritized actions to improve AI governance maturity")
                 )
          )
        ),
        fluidRow(
          column(4,
                 box(
                   title = "Critical Priority",
                   status = "danger",
                   solidHeader = TRUE,
                   width = 12,
                   uiOutput("critical_actions")
                 )
          ),
          column(4,
                 box(
                   title = "High Priority",
                   status = "warning",
                   solidHeader = TRUE,
                   width = 12,
                   uiOutput("high_actions")
                 )
          ),
          column(4,
                 box(
                   title = "Medium Priority",
                   status = "info",
                   solidHeader = TRUE,
                   width = 12,
                   uiOutput("medium_actions")
                 )
          )
        ),
        fluidRow(
          box(
            title = "AI-Generated Recommendations",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = FALSE,
            
            # LLM Provider Settings
            fluidRow(
              column(4,
                     selectInput("llm_provider", "LLM Provider",
                                 choices = c("llama.cpp (Local)" = "llama_cpp",
                                             "Ollama (Local)" = "ollama",
                                             "OpenAI" = "openai"),
                                 selected = "llama_cpp")
              ),
              column(4,
                     conditionalPanel(
                       condition = "input.llm_provider == 'llama_cpp'",
                       textInput("llama_cpp_model", "Model Name (display only)",
                                 value = "local-model",
                                 placeholder = "Name for your loaded model")
                     ),
                     conditionalPanel(
                       condition = "input.llm_provider == 'ollama'",
                       selectInput("ollama_model", "Ollama Model",
                                   choices = c("llama3.1:8b" = "llama3.1:8b",
                                               "llama3.1:70b" = "llama3.1:70b",
                                               "llama3.2:3b" = "llama3.2:3b",
                                               "mistral:7b" = "mistral:7b",
                                               "mixtral:8x7b" = "mixtral:8x7b",
                                               "codellama:13b" = "codellama:13b",
                                               "phi3:mini" = "phi3:mini",
                                               "gpt-oss:120b-cloud" = "gpt-oss:120b-cloud"),
                                   selected = "llama3.1:8b")
                     ),
                     conditionalPanel(
                       condition = "input.llm_provider == 'openai'",
                       selectInput("openai_model", "OpenAI Model",
                                   choices = c("gpt-4" = "gpt-4",
                                               "gpt-4-turbo" = "gpt-4-turbo",
                                               "gpt-4o" = "gpt-4o",
                                               "gpt-4o-mini" = "gpt-4o-mini",
                                               "gpt-3.5-turbo" = "gpt-3.5-turbo"),
                                   selected = "gpt-4")
                     )
              ),
              column(4,
                     conditionalPanel(
                       condition = "input.llm_provider == 'llama_cpp'",
                       textInput("llama_cpp_url", "llama.cpp Server URL",
                                 value = "http://localhost:8080",
                                 placeholder = "http://localhost:8080")
                     ),
                     conditionalPanel(
                       condition = "input.llm_provider == 'ollama'",
                       textInput("ollama_url", "Ollama Server URL",
                                 value = "http://localhost:11434")
                     ),
                     conditionalPanel(
                       condition = "input.llm_provider == 'openai'",
                       passwordInput("openai_key", "OpenAI API Key",
                                     placeholder = "sk-... (or set OPENAI_API_KEY env var)")
                     )
              )
            ),
            
            # Status indicator
            fluidRow(
              column(12,
                     uiOutput("llm_status")
              )
            ),
            
            hr(),
            
            div(style = "text-align: center; margin-bottom: 15px;",
                actionButton("generate_llm_actions", "Generate AI Recommendations",
                             icon = icon("robot"), class = "btn-info btn-lg"),
                actionButton("test_llm_connection", "Test Connection",
                             icon = icon("plug"), class = "btn-default",
                             style = "margin-left: 10px;")
            ),
            uiOutput("llm_recommendations")
          )
        ),
        fluidRow(
          box(
            title = "Benefit vs Effort Matrix",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("benefit_effort_matrix", height = "400px")
          )
        )
      ),
      
      # =========================================================================
      # REPORTS TAB
      # =========================================================================
      tabItem(
        tabName = "reports",
        fluidRow(
          column(12,
                 div(class = "section-header",
                     h3(icon("file-export"), " Reports & Export"),
                     p("Generate and download assessment reports for stakeholder communication")
                 )
          )
        ),
        fluidRow(
          column(4,
                 box(
                   title = "Executive Summary",
                   status = "primary",
                   solidHeader = TRUE,
                   width = 12,
                   p("High-level overview for executive leadership and board reporting."),
                   downloadButton("download_executive_summary", "Download Executive Summary",
                                  class = "btn-primary btn-block")
                 )
          ),
          column(4,
                 box(
                   title = "Detailed Assessment",
                   status = "info",
                   solidHeader = TRUE,
                   width = 12,
                   p("Complete assessment with all questions, scores, and action items."),
                   downloadButton("download_detailed_report", "Download Detailed Report",
                                  class = "btn-info btn-block")
                 )
          ),
          column(4,
                 box(
                   title = "Action Plan Export",
                   status = "success",
                   solidHeader = TRUE,
                   width = 12,
                   p("Prioritized action items for project planning and tracking."),
                   downloadButton("download_action_plan", "Download Action Plan",
                                  class = "btn-success btn-block")
                 )
          )
        ),
        fluidRow(
          box(
            title = "Assessment History (Recursive Tracking)",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            p("Track governance maturity progression across assessment cycles."),
            DTOutput("assessment_history_table"),
            br(),
            actionButton("start_new_cycle", "Start New Assessment Cycle",
                         icon = icon("plus-circle"), class = "btn-warning")
          )
        )
      )
    )
  )
)

# =============================================================================
# SERVER LOGIC
# =============================================================================

server <- function(input, output, session) {
  
  # ===========================================================================
  # REACTIVE VALUES
  # ===========================================================================
  
  # Assessment data storage
  assessment_data <- reactiveValues(
    responses = list(),
    last_saved = NULL,
    cycle_number = 1,
    history = data.frame()
  )
  
  # Initialize responses for all sections
  observe({
    for (i in 1:8) {
      section_name <- paste0("gov", i)
      section_data <- get(paste0("gov_section", i))
      
      if (is.null(assessment_data$responses[[section_name]])) {
        assessment_data$responses[[section_name]] <- data.frame(
          Code = section_data$Code,
          Question = section_data$Assessment_Question,
          Description = section_data$Description,
          Current = section_data$Default_Current,
          Target = section_data$Default_Target,
          Action_Items = rep("", nrow(section_data)),
          Benefit = rep(1, nrow(section_data)),
          Effort = rep(1, nrow(section_data)),
          stringsAsFactors = FALSE
        )
      }
    }
  })
  
  # ===========================================================================
  # HOME AND HOW-TO PAGE RENDERING
  # ===========================================================================

  # Render Home page markdown
  output$home_content <- renderUI({
    home_md_path <- file.path("www", "home.md")
    if (file.exists(home_md_path)) {
      md_content <- paste(readLines(home_md_path, warn = FALSE), collapse = "\n")
      HTML(markdown::markdownToHTML(text = md_content, fragment.only = TRUE))
    } else {
      div(
        h2("Welcome to AI Governance Assessment"),
        p("Home page content not found. Please ensure www/home.md exists.")
      )
    }
  })

  # Render How-To page markdown
  output$howto_content <- renderUI({
    howto_md_path <- file.path("www", "howto.md")
    if (file.exists(howto_md_path)) {
      md_content <- paste(readLines(howto_md_path, warn = FALSE), collapse = "\n")
      HTML(markdown::markdownToHTML(text = md_content, fragment.only = TRUE))
    } else {
      div(
        h2("How to Use This Tool"),
        p("How-to guide not found. Please ensure www/howto.md exists.")
      )
    }
  })

  # ===========================================================================
  # QUESTION RENDERING FUNCTION
  # ===========================================================================

  render_questions <- function(section_num) {
    section_name <- paste0("gov", section_num)
    section_data <- get(paste0("gov_section", section_num))
    
    renderUI({
      req(assessment_data$responses[[section_name]])
      
      lapply(1:nrow(section_data), function(i) {
        q <- section_data[i, ]
        q_id <- gsub("[^A-Za-z0-9]", "_", q$Code)
        current_val <- assessment_data$responses[[section_name]]$Current[i]
        target_val <- assessment_data$responses[[section_name]]$Target[i]
        gap <- target_val - current_val
        
        # Determine card class based on gap
        card_class <- "question-card"
        if (gap >= 2) card_class <- paste(card_class, "gap-high")
        else if (gap >= 1) card_class <- paste(card_class, "gap-medium")
        else if (current_val == target_val) card_class <- paste(card_class, "completed")
        
        div(class = card_class,
            div(class = "question-code", q$Code),
            div(class = "question-text", q$Assessment_Question),
            div(class = "question-description", q$Description),
            
            fluidRow(
              column(3,
                     selectInput(
                       inputId = paste0("current_", section_num, "_", q_id),
                       label = "Current Level",
                       choices = level_choices,
                       selected = num_to_level(current_val),
                       width = "100%"
                     )
              ),
              column(3,
                     selectInput(
                       inputId = paste0("target_", section_num, "_", q_id),
                       label = "Target Level",
                       choices = level_choices,
                       selected = num_to_level(target_val),
                       width = "100%"
                     )
              ),
              column(2,
                     div(style = "margin-top: 25px;",
                         span(class = paste0("gap-indicator gap-", tolower(calculate_priority(gap, current_val))),
                              paste("Gap:", gap))
                     )
              ),
              column(4,
                     textAreaInput(
                       inputId = paste0("actions_", section_num, "_", q_id),
                       label = "Action Items",
                       value = assessment_data$responses[[section_name]]$Action_Items[i],
                       placeholder = "Enter specific action items to close the gap...",
                       rows = 2,
                       width = "100%"
                     )
              )
            ),
            
            fluidRow(
              column(6,
                     sliderInput(
                       inputId = paste0("benefit_", section_num, "_", q_id),
                       label = "Expected Benefit",
                       min = 0, max = 2, value = 1,
                       step = 1,
                       ticks = TRUE,
                       width = "100%"
                     )
              ),
              column(6,
                     sliderInput(
                       inputId = paste0("effort_", section_num, "_", q_id),
                       label = "Implementation Effort",
                       min = 0, max = 2, value = 1,
                       step = 1,
                       ticks = TRUE,
                       width = "100%"
                     )
              )
            )
        )
      })
    })
  }
  
  # Render all section questions
  output$gov1_questions <- render_questions(1)
  output$gov2_questions <- render_questions(2)
  output$gov3_questions <- render_questions(3)
  output$gov4_questions <- render_questions(4)
  output$gov5_questions <- render_questions(5)
  output$gov6_questions <- render_questions(6)
  output$gov7_questions <- render_questions(7)
  output$gov8_questions <- render_questions(8)
  
  # ===========================================================================
  # OBSERVERS FOR INPUT CHANGES
  # ===========================================================================
  
  # Create observers for each section
  lapply(1:8, function(section_num) {
    section_name <- paste0("gov", section_num)
    section_data <- get(paste0("gov_section", section_num))
    
    lapply(1:nrow(section_data), function(i) {
      q <- section_data[i, ]
      q_id <- gsub("[^A-Za-z0-9]", "_", q$Code)
      
      # Current level observer
      observeEvent(input[[paste0("current_", section_num, "_", q_id)]], {
        val <- input[[paste0("current_", section_num, "_", q_id)]]
        if (!is.null(val)) {
          assessment_data$responses[[section_name]]$Current[i] <- level_to_num(val)
        }
      }, ignoreInit = TRUE)
      
      # Target level observer
      observeEvent(input[[paste0("target_", section_num, "_", q_id)]], {
        val <- input[[paste0("target_", section_num, "_", q_id)]]
        if (!is.null(val)) {
          assessment_data$responses[[section_name]]$Target[i] <- level_to_num(val)
        }
      }, ignoreInit = TRUE)
      
      # Action items observer
      observeEvent(input[[paste0("actions_", section_num, "_", q_id)]], {
        val <- input[[paste0("actions_", section_num, "_", q_id)]]
        if (!is.null(val)) {
          assessment_data$responses[[section_name]]$Action_Items[i] <- val
        }
      }, ignoreInit = TRUE)
      
      # Benefit observer
      observeEvent(input[[paste0("benefit_", section_num, "_", q_id)]], {
        val <- input[[paste0("benefit_", section_num, "_", q_id)]]
        if (!is.null(val)) {
          assessment_data$responses[[section_name]]$Benefit[i] <- val
        }
      }, ignoreInit = TRUE)
      
      # Effort observer
      observeEvent(input[[paste0("effort_", section_num, "_", q_id)]], {
        val <- input[[paste0("effort_", section_num, "_", q_id)]]
        if (!is.null(val)) {
          assessment_data$responses[[section_name]]$Effort[i] <- val
        }
      }, ignoreInit = TRUE)
    })
  })
  
  # ===========================================================================
  # NAVIGATION OBSERVERS
  # ===========================================================================
  
  observeEvent(input$nav_to_gov2, { updateTabItems(session, "sidebar_menu", "gov2") })
  observeEvent(input$nav_to_gov1_from_2, { updateTabItems(session, "sidebar_menu", "gov1") })
  observeEvent(input$nav_to_gov3, { updateTabItems(session, "sidebar_menu", "gov3") })
  observeEvent(input$nav_to_gov2_from_3, { updateTabItems(session, "sidebar_menu", "gov2") })
  observeEvent(input$nav_to_gov4, { updateTabItems(session, "sidebar_menu", "gov4") })
  observeEvent(input$nav_to_gov3_from_4, { updateTabItems(session, "sidebar_menu", "gov3") })
  observeEvent(input$nav_to_gov5, { updateTabItems(session, "sidebar_menu", "gov5") })
  observeEvent(input$nav_to_gov4_from_5, { updateTabItems(session, "sidebar_menu", "gov4") })
  observeEvent(input$nav_to_gov6, { updateTabItems(session, "sidebar_menu", "gov6") })
  observeEvent(input$nav_to_gov5_from_6, { updateTabItems(session, "sidebar_menu", "gov5") })
  observeEvent(input$nav_to_gov7, { updateTabItems(session, "sidebar_menu", "gov7") })
  observeEvent(input$nav_to_gov6_from_7, { updateTabItems(session, "sidebar_menu", "gov6") })
  observeEvent(input$nav_to_gov8, { updateTabItems(session, "sidebar_menu", "gov8") })
  observeEvent(input$nav_to_gov7_from_8, { updateTabItems(session, "sidebar_menu", "gov7") })
  
  observeEvent(input$complete_assessment, {
    showNotification("Assessment completed! View results in Dashboard and Gap Analysis.",
                     type = "message", duration = 5)
    updateTabItems(session, "sidebar_menu", "dashboard")
  })
  
  # ===========================================================================
  # COMBINED DATA REACTIVE
  # ===========================================================================
  
  combined_data <- reactive({
    req(assessment_data$responses)
    
    all_data <- do.call(rbind, lapply(1:8, function(i) {
      section_name <- paste0("gov", i)
      df <- assessment_data$responses[[section_name]]
      if (!is.null(df)) {
        df$Section <- paste0("GOV ", i)
        df$Section_Name <- section_info$title[i]
        df
      }
    }))
    
    if (!is.null(all_data) && nrow(all_data) > 0) {
      all_data$Gap <- all_data$Target - all_data$Current
      all_data$Priority <- mapply(calculate_priority, all_data$Gap, all_data$Current)
    }
    
    all_data
  })
  
  # Domain summary reactive
  domain_summary <- reactive({
    df <- combined_data()
    req(df)
    
    df %>%
      group_by(Section, Section_Name) %>%
      summarise(
        Avg_Current = mean(Current, na.rm = TRUE),
        Avg_Target = mean(Target, na.rm = TRUE),
        Avg_Gap = mean(Gap, na.rm = TRUE),
        Questions = n(),
        Critical_High = sum(Priority %in% c("Critical", "High")),
        .groups = "drop"
      )
  })
  
  # ===========================================================================
  # DASHBOARD OUTPUTS
  # ===========================================================================
  
  # Overall score
  output$overall_score_text <- renderText({
    df <- combined_data()
    req(df)
    sprintf("%.1f", mean(df$Current, na.rm = TRUE))
  })
  
  # Completed questions
  output$completed_count <- renderText({
    df <- combined_data()
    req(df)
    nrow(df)
  })
  
  output$total_questions <- renderText({
    df <- combined_data()
    req(df)
    nrow(df)
  })
  
  # Critical gaps
  output$critical_gaps <- renderText({
    df <- combined_data()
    req(df)
    sum(df$Priority %in% c("Critical", "High"))
  })
  
  # Assessment cycle
  output$assessment_cycle <- renderText({
    paste0("#", assessment_data$cycle_number)
  })
  
  output$last_updated <- renderText({
    if (is.null(assessment_data$last_saved)) {
      "Not yet saved"
    } else {
      format(assessment_data$last_saved, "%Y-%m-%d %H:%M")
    }
  })
  
  # Sidebar status
  output$sidebar_status <- renderUI({
    df <- combined_data()
    req(df)
    
    overall <- mean(df$Current, na.rm = TRUE)
    target <- mean(df$Target, na.rm = TRUE)
    pct <- (overall / 4) * 100
    
    div(
      div(style = "margin-bottom: 10px;",
          tags$small("Overall Progress"),
          div(class = "progress", style = "margin-top: 5px;",
              div(class = "progress-bar bg-info",
                  role = "progressbar",
                  style = paste0("width: ", pct, "%;"),
                  sprintf("%.0f%%", pct))
          )
      ),
      tags$small(style = "color: #aaa;",
                 sprintf("Current: %.1f | Target: %.1f", overall, target))
    )
  })
  
  # Radar chart
  output$radar_chart <- renderPlotly({
    df <- domain_summary()
    req(df)
    
    # Create radar chart data
    categories <- df$Section_Name
    current_values <- df$Avg_Current
    target_values <- df$Avg_Target
    
    plot_ly(type = 'scatterpolar', mode = 'lines+markers') %>%
      add_trace(
        r = c(current_values, current_values[1]),
        theta = c(categories, categories[1]),
        name = 'Current State',
        fill = 'toself',
        fillcolor = 'rgba(60, 141, 188, 0.3)',
        line = list(color = '#3c8dbc', width = 2),
        marker = list(size = 8, color = '#3c8dbc')
      ) %>%
      add_trace(
        r = c(target_values, target_values[1]),
        theta = c(categories, categories[1]),
        name = 'Target State',
        fill = 'toself',
        fillcolor = 'rgba(40, 167, 69, 0.2)',
        line = list(color = '#28a745', width = 2, dash = 'dash'),
        marker = list(size = 8, color = '#28a745')
      ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 4),
            tickvals = c(0, 1, 2, 3, 4),
            ticktext = c("0", "1", "2", "3", "4")
          )
        ),
        showlegend = TRUE,
        legend = list(orientation = 'h', y = -0.1),
        margin = list(t = 30, b = 50)
      )
  })
  
  # Domain comparison chart
  output$domain_comparison_chart <- renderPlotly({
    df <- domain_summary()
    req(df)
    
    plot_ly(df, y = ~Section_Name, x = ~Avg_Current, type = 'bar',
            name = 'Current', orientation = 'h',
            marker = list(color = '#3c8dbc')) %>%
      add_trace(x = ~Avg_Target, name = 'Target',
                marker = list(color = '#28a745')) %>%
      layout(
        barmode = 'group',
        xaxis = list(title = 'Maturity Level', range = c(0, 4.5)),
        yaxis = list(title = '', categoryorder = 'array',
                     categoryarray = rev(df$Section_Name)),
        legend = list(orientation = 'h', y = -0.15),
        margin = list(l = 150)
      )
  })
  
  # Gap waterfall chart
  output$gap_waterfall <- renderPlotly({
    df <- domain_summary()
    req(df)
    
    df <- df %>% arrange(desc(Avg_Gap))
    
    plot_ly(df, x = ~Section_Name, y = ~Avg_Gap, type = 'bar',
            marker = list(color = ifelse(df$Avg_Gap >= 2, '#dc3545',
                                         ifelse(df$Avg_Gap >= 1, '#ffc107', '#28a745')))) %>%
      layout(
        xaxis = list(title = '', tickangle = -45),
        yaxis = list(title = 'Average Gap (Target - Current)', range = c(0, max(df$Avg_Gap) * 1.2)),
        margin = list(b = 100)
      )
  })
  
  # Priority pie chart
  output$priority_pie <- renderPlotly({
    df <- combined_data()
    req(df)
    
    priority_counts <- df %>%
      group_by(Priority) %>%
      summarise(Count = n(), .groups = "drop")
    
    colors <- c("Critical" = "#dc3545", "High" = "#fd7e14",
                "Medium" = "#ffc107", "Low" = "#28a745")
    
    plot_ly(priority_counts, labels = ~Priority, values = ~Count, type = 'pie',
            marker = list(colors = colors[priority_counts$Priority]),
            textinfo = 'label+value',
            textposition = 'inside') %>%
      layout(showlegend = FALSE)
  })
  
  # Top actions dashboard
  output$top_actions_dashboard <- renderUI({
    df <- combined_data()
    req(df)
    
    top_items <- df %>%
      filter(Priority %in% c("Critical", "High")) %>%
      arrange(desc(Gap), Current) %>%
      head(5)
    
    if (nrow(top_items) == 0) {
      return(p("No critical or high priority items. Great job!"))
    }
    
    tagList(
      lapply(1:nrow(top_items), function(i) {
        item <- top_items[i, ]
        div(class = paste0("priority-item priority-", tolower(item$Priority)),
            strong(item$Code), " - ", item$Question,
            br(),
            tags$small(
              span(class = paste0("maturity-badge maturity-", item$Current),
                   paste("Current:", item$Current)),
              " → ",
              span(class = paste0("maturity-badge maturity-", item$Target),
                   paste("Target:", item$Target)),
              " | Gap: ", item$Gap
            ),
            if (item$Action_Items != "") {
              div(style = "margin-top: 5px; font-size: 12px; color: #666;",
                  icon("tasks"), " ", item$Action_Items)
            }
        )
      })
    )
  })
  
  # ===========================================================================
  # GAP ANALYSIS OUTPUTS
  # ===========================================================================
  
  output$detailed_gap_chart <- renderPlotly({
    df <- combined_data()
    req(df)
    
    df <- df %>% arrange(desc(Gap))
    
    plot_ly(df, y = ~Code, x = ~Gap, type = 'bar', orientation = 'h',
            marker = list(color = case_when(
              df$Priority == "Critical" ~ "#dc3545",
              df$Priority == "High" ~ "#fd7e14",
              df$Priority == "Medium" ~ "#ffc107",
              TRUE ~ "#28a745"
            )),
            text = ~paste("Current:", Current, "| Target:", Target),
            hoverinfo = 'text+x') %>%
      layout(
        xaxis = list(title = 'Gap (Target - Current)'),
        yaxis = list(title = '', categoryorder = 'array', categoryarray = rev(df$Code)),
        margin = list(l = 80)
      )
  })
  
  output$gap_analysis_table <- renderDT({
    df <- combined_data()
    req(df)
    
    df %>%
      select(Code, Question, Section_Name, Current, Target, Gap, Priority, Action_Items) %>%
      arrange(desc(Gap)) %>%
      datatable(
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        filter = 'top'
      ) %>%
      formatStyle('Priority',
                  backgroundColor = styleEqual(
                    c('Critical', 'High', 'Medium', 'Low'),
                    c('#dc3545', '#fd7e14', '#ffc107', '#28a745')
                  ),
                  color = styleEqual(
                    c('Critical', 'High', 'Medium', 'Low'),
                    c('white', 'white', 'black', 'white')
                  ))
  })
  
  # ===========================================================================
  # ACTION PLAN OUTPUTS
  # ===========================================================================
  
  render_priority_actions <- function(priority_filter) {
    renderUI({
      df <- combined_data()
      req(df)
      
      items <- df %>%
        filter(Priority %in% priority_filter) %>%
        arrange(desc(Gap))
      
      if (nrow(items) == 0) {
        return(p(paste("No", tolower(priority_filter[1]), "priority items.")))
      }
      
      tagList(
        lapply(1:nrow(items), function(i) {
          item <- items[i, ]
          div(class = paste0("priority-item priority-", tolower(item$Priority)),
              strong(item$Code), br(),
              tags$small(item$Question),
              div(style = "margin-top: 8px;",
                  span(class = paste0("maturity-badge maturity-", item$Current),
                       item$Current),
                  " → ",
                  span(class = paste0("maturity-badge maturity-", item$Target),
                       item$Target)
              ),
              if (item$Action_Items != "") {
                div(style = "margin-top: 8px; padding: 8px; background: #f8f9fa; border-radius: 4px;",
                    tags$small(icon("tasks"), " ", item$Action_Items))
              }
          )
        })
      )
    })
  }
  
  output$critical_actions <- render_priority_actions("Critical")
  output$high_actions <- render_priority_actions("High")
  output$medium_actions <- render_priority_actions("Medium")
  
  # Benefit vs Effort Matrix
  output$benefit_effort_matrix <- renderPlotly({
    df <- combined_data()
    req(df)
    
    # Filter to items with gaps
    df_gaps <- df %>% filter(Gap > 0)
    
    if (nrow(df_gaps) == 0) {
      return(plotly_empty() %>% layout(title = "No gaps to display"))
    }
    
    plot_ly(df_gaps, x = ~Effort, y = ~Benefit, type = 'scatter', mode = 'markers+text',
            text = ~Code, textposition = 'top center',
            marker = list(
              size = ~Gap * 10 + 10,
              color = case_when(
                df_gaps$Priority == "Critical" ~ "#dc3545",
                df_gaps$Priority == "High" ~ "#fd7e14",
                df_gaps$Priority == "Medium" ~ "#ffc107",
                TRUE ~ "#28a745"
              ),
              opacity = 0.7,
              line = list(color = 'white', width = 1)
            ),
            hovertext = ~paste(Code, "<br>", Question, "<br>Gap:", Gap),
            hoverinfo = 'text') %>%
      layout(
        xaxis = list(
          title = 'Implementation Effort →',
          tickvals = c(0, 1, 2),
          ticktext = c('High Effort', 'Medium', 'Low Effort'),
          range = c(-0.5, 2.5)
        ),
        yaxis = list(
          title = '← Expected Benefit',
          tickvals = c(0, 1, 2),
          ticktext = c('Low Benefit', 'Medium', 'High Benefit'),
          range = c(-0.5, 2.5)
        ),
        shapes = list(
          # Quick wins quadrant
          list(type = 'rect', x0 = 1.5, x1 = 2.5, y0 = 1.5, y1 = 2.5,
               fillcolor = 'rgba(40, 167, 69, 0.1)', line = list(width = 0)),
          # Strategic initiatives quadrant
          list(type = 'rect', x0 = -0.5, x1 = 1.5, y0 = 1.5, y1 = 2.5,
               fillcolor = 'rgba(23, 162, 184, 0.1)', line = list(width = 0))
        ),
        annotations = list(
          list(x = 2, y = 2.3, text = "Quick Wins", showarrow = FALSE,
               font = list(color = '#28a745', size = 12)),
          list(x = 0.5, y = 2.3, text = "Strategic", showarrow = FALSE,
               font = list(color = '#17a2b8', size = 12))
        )
      )
  })
  
  # ===========================================================================
  # LLM INTEGRATION (via ellmer package - supports Ollama and OpenAI)
  # ===========================================================================
  
  llm_results <- reactiveVal(NULL)
  llm_connection_status <- reactiveVal(list(connected = FALSE, message = "Not tested"))
  
  # Function to call LLM - supports llama.cpp, Ollama, and OpenAI
  # llama.cpp uses OpenAI-compatible API at /v1/chat/completions
  call_llm <- function(prompt, provider, model, base_url = NULL, api_key = NULL) {

    tryCatch({

      if (provider == "llama_cpp") {
        # llama.cpp server with OpenAI-compatible API
        effective_url <- if (!is.null(base_url) && base_url != "") base_url else LLAMA_CPP_BASE_URL
        endpoint <- paste0(effective_url, "/v1/chat/completions")

        # Build request body
        body <- list(
          messages = list(
            list(role = "system", content = SYSTEM_PROMPT),
            list(role = "user", content = prompt)
          ),
          temperature = 0.7,
          max_tokens = 2048,
          stream = FALSE
        )

        # Make POST request
        response <- POST(
          url = endpoint,
          body = toJSON(body, auto_unbox = TRUE),
          content_type_json(),
          encode = "raw",
          timeout(120)  # 2 minute timeout for long responses
        )

        # Check for HTTP errors
        if (http_error(response)) {
          status <- status_code(response)
          error_body <- tryCatch(content(response, "text", encoding = "UTF-8"), error = function(e) "")

          if (status == 503) {
            return(list(
              success = FALSE,
              message = paste0(
                "llama.cpp server is busy (503). The server may be:\n",
                "- Still loading the model\n",
                "- Processing another request\n\n",
                "Try again in a moment."
              )
            ))
          }

          return(list(
            success = FALSE,
            message = paste0("HTTP ", status, " error from llama.cpp server:\n", error_body)
          ))
        }

        # Parse response
        result <- content(response, "parsed", encoding = "UTF-8")

        if (!is.null(result$choices) && length(result$choices) > 0) {
          content_text <- result$choices[[1]]$message$content
          return(list(success = TRUE, content = content_text))
        } else if (!is.null(result$error)) {
          return(list(success = FALSE, message = result$error$message))
        } else {
          return(list(success = FALSE, message = "Unexpected response format from llama.cpp"))
        }

      } else if (provider == "ollama") {
        # Ollama - use ellmer if available, otherwise use API directly
        if (ELLMER_AVAILABLE) {
          chat <- chat_ollama(
            system_prompt = SYSTEM_PROMPT,
            model = model,
            base_url = if (!is.null(base_url) && base_url != "") base_url else OLLAMA_BASE_URL,
            echo = "none"
          )
          response <- chat$chat(prompt)
          return(list(success = TRUE, content = response))
        } else {
          # Fallback: Use Ollama's OpenAI-compatible API
          effective_url <- if (!is.null(base_url) && base_url != "") base_url else OLLAMA_BASE_URL
          endpoint <- paste0(effective_url, "/v1/chat/completions")

          body <- list(
            model = model,
            messages = list(
              list(role = "system", content = SYSTEM_PROMPT),
              list(role = "user", content = prompt)
            ),
            temperature = 0.7,
            stream = FALSE
          )

          response <- POST(
            url = endpoint,
            body = toJSON(body, auto_unbox = TRUE),
            content_type_json(),
            encode = "raw",
            timeout(120)
          )

          if (http_error(response)) {
            return(list(success = FALSE, message = paste("HTTP error:", status_code(response))))
          }

          result <- content(response, "parsed", encoding = "UTF-8")
          if (!is.null(result$choices) && length(result$choices) > 0) {
            return(list(success = TRUE, content = result$choices[[1]]$message$content))
          }
          return(list(success = FALSE, message = "Unexpected response from Ollama"))
        }

      } else if (provider == "openai") {
        # OpenAI - use ellmer if available
        if (!ELLMER_AVAILABLE) {
          return(list(
            success = FALSE,
            message = "OpenAI requires ellmer package. Install with: install.packages('ellmer')"
          ))
        }

        effective_key <- if (!is.null(api_key) && api_key != "") api_key else Sys.getenv("OPENAI_API_KEY")

        if (effective_key == "") {
          return(list(
            success = FALSE,
            message = "OpenAI API key not provided. Enter key above or set OPENAI_API_KEY environment variable."
          ))
        }

        old_key <- Sys.getenv("OPENAI_API_KEY")
        Sys.setenv(OPENAI_API_KEY = effective_key)
        on.exit(Sys.setenv(OPENAI_API_KEY = old_key), add = TRUE)

        chat <- chat_openai(
          system_prompt = SYSTEM_PROMPT,
          model = model,
          echo = "none"
        )
        response <- chat$chat(prompt)
        return(list(success = TRUE, content = response))

      } else {
        return(list(success = FALSE, message = paste("Unknown provider:", provider)))
      }

    }, error = function(e) {
      error_msg <- e$message

      # Provide helpful error messages based on provider and error type
      if (provider == "llama_cpp") {
        if (grepl("connection refused|Could not resolve host|Failed to connect", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Cannot connect to llama.cpp server at ", base_url, "\n\n",
            "Make sure llama-server is running:\n",
            "1. Start the server: ./llama-server -m /path/to/model.gguf\n",
            "2. Or use: LLAMA_MODEL_PATH=/path/to/model.gguf ./start_llama_rr.sh start\n",
            "3. Verify server is accessible at ", base_url, "/health"
          )
        } else if (grepl("timeout", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Request to llama.cpp server timed out.\n\n",
            "The model may be generating a long response. Try:\n",
            "- Reducing max_tokens\n",
            "- Using a smaller/faster model\n",
            "- Checking server load"
          )
        }
      } else if (provider == "ollama") {
        if (grepl("connection refused|Could not resolve host", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Cannot connect to Ollama server at ", base_url, "\n\n",
            "Make sure Ollama is running:\n",
            "1. Install Ollama: https://ollama.ai\n",
            "2. Start server: 'ollama serve'\n",
            "3. Pull model: 'ollama pull ", model, "'"
          )
        }
      }

      list(success = FALSE, message = error_msg)
    })
  }
  
  # Test LLM connection
  observeEvent(input$test_llm_connection, {
    provider <- input$llm_provider
    model <- if (provider == "llama_cpp") {
      input$llama_cpp_model
    } else if (provider == "ollama") {
      input$ollama_model
    } else {
      input$openai_model
    }
    base_url <- if (provider == "llama_cpp") {
      input$llama_cpp_url
    } else if (provider == "ollama") {
      input$ollama_url
    } else {
      NULL
    }
    api_key <- if (provider == "openai") input$openai_key else NULL

    showNotification("Testing connection...", type = "message", duration = 2)

    result <- call_llm(
      prompt = "Respond with exactly: 'Connection successful'",
      provider = provider,
      model = model,
      base_url = base_url,
      api_key = api_key
    )

    if (result$success) {
      llm_connection_status(list(connected = TRUE, message = paste("Connected to", model)))
      showNotification(paste("Success! Connected to", model), type = "message")
    } else {
      llm_connection_status(list(connected = FALSE, message = result$message))
      showNotification(result$message, type = "error", duration = 10)
    }
  })
  
  # LLM Status indicator
  output$llm_status <- renderUI({
    status <- llm_connection_status()
    provider <- input$llm_provider
    model <- if (provider == "llama_cpp") {
      input$llama_cpp_model
    } else if (provider == "ollama") {
      input$ollama_model
    } else {
      input$openai_model
    }

    if (status$connected) {
      div(class = "alert alert-success", style = "padding: 8px; margin: 5px 0;",
          icon("check-circle"), " Connected to ", strong(model))
    } else {
      div(class = "alert alert-warning", style = "padding: 8px; margin: 5px 0;",
          icon("exclamation-triangle"), " ",
          if (provider == "llama_cpp") {
            tagList("llama.cpp: Ensure llama-server is running at ", tags$code(input$llama_cpp_url))
          } else if (provider == "ollama") {
            tagList("Ollama: Ensure server is running at ", tags$code(input$ollama_url),
                    " and model ", tags$code(model), " is pulled")
          } else {
            "OpenAI: Enter API key or set OPENAI_API_KEY environment variable"
          }
      )
    }
  })
  
  # Generate recommendations
  observeEvent(input$generate_llm_actions, {
    df <- combined_data()
    req(df)

    provider <- input$llm_provider
    model <- if (provider == "llama_cpp") {
      input$llama_cpp_model
    } else if (provider == "ollama") {
      input$ollama_model
    } else {
      input$openai_model
    }
    base_url <- if (provider == "llama_cpp") {
      input$llama_cpp_url
    } else if (provider == "ollama") {
      input$ollama_url
    } else {
      NULL
    }
    api_key <- if (provider == "openai") input$openai_key else NULL
    
    showNotification(
      paste("Generating recommendations using", model, "..."),
      type = "message",
      duration = NULL,
      id = "llm_progress"
    )
    
    # Build prompt with assessment gaps
    gap_items <- df %>%
      filter(Gap > 0) %>%
      arrange(desc(Gap)) %>%
      head(10)
    
    if (nrow(gap_items) == 0) {
      removeNotification(id = "llm_progress")
      showNotification("No gaps found to analyze.", type = "warning")
      return()
    }
    
    prompt <- paste0(
      "Based on the following AI Governance Assessment gaps aligned with NIST AI RMF, ",
      "provide specific, actionable recommendations for each item. ",
      "Consider healthcare regulatory requirements (HIPAA, CMIA) and organizational implementation feasibility.\n\n",
      "Assessment Gaps:\n",
      paste(sapply(1:nrow(gap_items), function(i) {
        item <- gap_items[i, ]
        sprintf("%s: %s\nCurrent Level: %d, Target Level: %d, Gap: %d\n",
                item$Code, item$Question, item$Current, item$Target, item$Gap)
      }), collapse = "\n"),
      "\n\nFor each governance item, provide:\n",
      "1. **Specific Action Steps** - Concrete tasks to close the gap\n",
      "2. **Key Stakeholders** - Who needs to be involved\n",
      "3. **Timeline** - Quick win (1-3 months) vs Strategic initiative (6-12 months)\n",
      "4. **Dependencies** - Prerequisites or related items\n\n",
      "Format your response clearly with the GOV code as headers."
    )
    
    result <- call_llm(
      prompt = prompt,
      provider = provider,
      model = model,
      base_url = base_url,
      api_key = api_key
    )
    
    removeNotification(id = "llm_progress")
    
    if (result$success) {
      llm_results(result$content)
      llm_connection_status(list(connected = TRUE, message = paste("Connected to", model)))
      showNotification("Recommendations generated successfully!", type = "message")
    } else {
      showNotification(result$message, type = "error", duration = 10)
    }
  })
  
  observeEvent(input$generate_ai_recommendations, {
    # Navigate to action plan tab when sidebar button clicked
    updateTabItems(session, "sidebar_menu", "action_plan")
  })
  
  output$llm_recommendations <- renderUI({
    result <- llm_results()

    if (is.null(result)) {
      return(
        div(
          p("Click 'Generate AI Recommendations' to get AI-powered insights based on your assessment."),
          hr(),
          h5("Setup Instructions:"),
          tags$ol(
            tags$li(
              strong("For llama.cpp (Local, Recommended):"),
              tags$ul(
                tags$li("Start llama-server with your model:"),
                tags$li(tags$code("./llama-server -m /path/to/model.gguf --port 8080")),
                tags$li("Or use the project scripts:"),
                tags$li(tags$code("LLAMA_MODEL_PATH=/path/to/model.gguf ./start_llama_rr.sh start")),
                tags$li("Verify server at: ", tags$code("http://localhost:8080/health"))
              )
            ),
            tags$li(
              strong("For Ollama (Local, Easy Setup):"),
              tags$ul(
                tags$li("Install Ollama: ", tags$a(href = "https://ollama.ai", target = "_blank", "https://ollama.ai")),
                tags$li("Start server: ", tags$code("ollama serve")),
                tags$li("Pull model: ", tags$code("ollama pull llama3.1:8b"))
              )
            ),
            tags$li(
              strong("For OpenAI (Cloud):"),
              tags$ul(
                tags$li("Get API key from ", tags$a(href = "https://platform.openai.com", target = "_blank", "OpenAI Platform")),
                tags$li("Enter key above or set ", tags$code("OPENAI_API_KEY"), " environment variable")
              )
            )
          )
        )
      )
    }

    div(
      style = "white-space: pre-wrap; font-family: inherit; background: #f8f9fa; padding: 15px; border-radius: 8px;",
      result
    )
  })
  
  # ===========================================================================
  # SAVE/EXPORT FUNCTIONALITY
  # ===========================================================================
  
  observeEvent(input$save_assessment, {
    assessment_data$last_saved <- Sys.time()
    showNotification("Assessment progress saved!", type = "message")
  })
  
  # Executive Summary Download
  output$download_executive_summary <- downloadHandler(
    filename = function() {
      paste0("AI_Governance_Executive_Summary_", format(Sys.Date(), "%Y%m%d"), ".xlsx")
    },
    content = function(file) {
      df <- combined_data()
      summary_df <- domain_summary()
      
      wb <- createWorkbook()
      
      # Summary sheet
      addWorksheet(wb, "Executive Summary")
      writeData(wb, "Executive Summary", data.frame(
        Metric = c("Overall Maturity Score", "Target Score", "Assessment Cycle", "Date"),
        Value = c(sprintf("%.1f", mean(df$Current, na.rm = TRUE)),
                  sprintf("%.1f", mean(df$Target, na.rm = TRUE)),
                  assessment_data$cycle_number,
                  format(Sys.Date(), "%Y-%m-%d"))
      ), startRow = 1)
      
      writeData(wb, "Executive Summary", summary_df, startRow = 8)
      
      # Priority items sheet
      addWorksheet(wb, "Priority Actions")
      priority_df <- df %>%
        filter(Priority %in% c("Critical", "High")) %>%
        select(Code, Question, Current, Target, Gap, Priority, Action_Items)
      writeData(wb, "Priority Actions", priority_df)
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  
  # Detailed Report Download
  output$download_detailed_report <- downloadHandler(
    filename = function() {
      paste0("AI_Governance_Detailed_Report_", format(Sys.Date(), "%Y%m%d"), ".xlsx")
    },
    content = function(file) {
      df <- combined_data()
      
      wb <- createWorkbook()
      
      addWorksheet(wb, "Full Assessment")
      writeData(wb, "Full Assessment", df)
      
      addWorksheet(wb, "Domain Summary")
      writeData(wb, "Domain Summary", domain_summary())
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  
  # Action Plan Download
  output$download_action_plan <- downloadHandler(
    filename = function() {
      paste0("AI_Governance_Action_Plan_", format(Sys.Date(), "%Y%m%d"), ".xlsx")
    },
    content = function(file) {
      df <- combined_data()
      
      action_df <- df %>%
        filter(Gap > 0) %>%
        arrange(desc(Gap)) %>%
        select(Code, Question, Section_Name, Current, Target, Gap, Priority,
               Action_Items, Benefit, Effort) %>%
        mutate(
          Benefit_Label = case_when(
            Benefit == 0 ~ "Minimal",
            Benefit == 1 ~ "Moderate",
            Benefit == 2 ~ "Significant"
          ),
          Effort_Label = case_when(
            Effort == 0 ~ "Significant",
            Effort == 1 ~ "Moderate",
            Effort == 2 ~ "Minimal"
          )
        )
      
      wb <- createWorkbook()
      addWorksheet(wb, "Action Plan")
      writeData(wb, "Action Plan", action_df)
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  
  # Assessment History
  output$assessment_history_table <- renderDT({
    if (nrow(assessment_data$history) == 0) {
      return(datatable(data.frame(
        Cycle = integer(),
        Date = character(),
        Overall_Score = numeric(),
        Target_Score = numeric(),
        Critical_Gaps = integer()
      ), options = list(dom = 't'), rownames = FALSE))
    }
    
    datatable(assessment_data$history,
              options = list(pageLength = 10, dom = 'tip'),
              rownames = FALSE)
  })
  
  observeEvent(input$start_new_cycle, {
    df <- combined_data()
    
    # Save current cycle to history
    new_record <- data.frame(
      Cycle = assessment_data$cycle_number,
      Date = format(Sys.Date(), "%Y-%m-%d"),
      Overall_Score = round(mean(df$Current, na.rm = TRUE), 2),
      Target_Score = round(mean(df$Target, na.rm = TRUE), 2),
      Critical_Gaps = sum(df$Priority %in% c("Critical", "High"))
    )
    
    assessment_data$history <- rbind(assessment_data$history, new_record)
    assessment_data$cycle_number <- assessment_data$cycle_number + 1
    
    showNotification(paste("Started Assessment Cycle #", assessment_data$cycle_number),
                     type = "message")
  })
  
}

# =============================================================================
# RUN APPLICATION
# =============================================================================

shinyApp(ui = ui, server = server)
