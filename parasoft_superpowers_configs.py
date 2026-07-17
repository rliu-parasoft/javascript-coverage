import os

# =============================================================================
# jira-to-spec skill
# =============================================================================

# Required by jira-to-spec: Jira server base URL (without trailing slash)
JIRA_URL = "https://jira.parasoft.com"

# Required by jira-to-spec: Access token used by Jira API requests.
# Recommended: set environment variable JIRA_TOKEN and replace the value below with:
# os.getenv("JIRA_TOKEN")
JIRA_TOKEN = os.getenv("JIRA_TOKEN", "")

# Optional (jira-to-spec): Directory for spec files, relative to workspace root.
# If omitted or set to "", spec auto-save is disabled and spec content is shown in chat only.
SPEC_OUTPUT_DIR = "specs"

# =============================================================================
# finishing-a-development-branch skill (Bitbucket PR)
# =============================================================================

# Required by finishing-a-development-branch (Bitbucket): Server base URL (without trailing slash)
BITBUCKET_BASE_URL = "https://code.parasoftcn.com"

# Required by finishing-a-development-branch (Bitbucket): Project key (e.g. "SVA")
BITBUCKET_PROJECT_KEY = "JSC"

# Required by finishing-a-development-branch (Bitbucket): Repository slug (e.g. "soavirt-someip")
BITBUCKET_REPO_SLUG = "javascript-coverage"

# Required by finishing-a-development-branch (Bitbucket): Access token used by the API request.
# Recommended: set environment variable BITBUCKET_TOKEN and replace the value below with:
# os.getenv("BITBUCKET_TOKEN")
BITBUCKET_TOKEN = os.getenv("BITBUCKET_TOKEN", "")

# Optional (finishing-a-development-branch): PR platform.
# "github" or "bitbucket" (lowercase). If omitted, the skill will ask the user each time.
PR_PLATFORM = "bitbucket"

# Optional: Rule-scope routing for extracting-rules.
RULE_SCOPE_ROUTING = {
    "default_scope": "GLOBAL",
    "scopes": [
        {
            "label": "GLOBAL",
            "description": "Rule applies to both Javascript and Java workflows.",
            "target_file": "AGENTS.md",
        },
        {
            "label": "JAVA_ONLY",
            "description": "Rule applies only to Java workflow.",
            "target_file": "javascript-coverage/AGENTS.md",
        },
        {
            "label": "JAVASCRIPT_ONLY",
            "description": "Rule applies only to Javascript workflow.",
            "target_file": "integration/AGENTS.md",
        },
    ],
}

# Optional: Tie-breaker rules for extracting-rules scope classification.
SCOPE_TIE_BREAKERS = [
    "If the same rule affects both Javascript and Java workflows, classify as GLOBAL.",
    "Split into JAVA_ONLY and JAVASCRIPT_ONLY only when required behavior truly differs by layer.",
    "If behavior does not differ by layer, keep a single GLOBAL rule to avoid duplication.",
]
