#!/bin/bash
# Sytex API CLI

CONFIG_FILE="$HOME/.claude/skills/sytex/.env"
source "$CONFIG_FILE" 2>/dev/null

if [[ -z "$SYTEX_TOKEN" || -z "$SYTEX_ORG_ID" ]]; then
    echo "Error: Sytex not configured."
    echo "Run: ~/.claude/skills/sytex/config.sh setup"
    exit 1
fi

API_BASE="${SYTEX_BASE_URL:-https://app.sytex.io}/api"

echo "[Sytex] Organization: $SYTEX_ORG_ID" >&2

# HTTP request helpers
api_get() {
    local endpoint="$1"
    curl -s -X GET "${API_BASE}${endpoint}" \
        -H "Authorization: Token $SYTEX_TOKEN" \
        -H "Organization: $SYTEX_ORG_ID" \
        -H "Accept: application/json"
}

api_post() {
    local endpoint="$1"
    local data="$2"
    curl -s -X POST "${API_BASE}${endpoint}" \
        -H "Authorization: Token $SYTEX_TOKEN" \
        -H "Organization: $SYTEX_ORG_ID" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$data"
}

api_put() {
    local endpoint="$1"
    local data="$2"
    curl -s -X PUT "${API_BASE}${endpoint}" \
        -H "Authorization: Token $SYTEX_TOKEN" \
        -H "Organization: $SYTEX_ORG_ID" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$data"
}

api_patch() {
    local endpoint="$1"
    local data="$2"
    curl -s -X PATCH "${API_BASE}${endpoint}" \
        -H "Authorization: Token $SYTEX_TOKEN" \
        -H "Organization: $SYTEX_ORG_ID" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$data"
}

api_delete() {
    local endpoint="$1"
    curl -s -X DELETE "${API_BASE}${endpoint}" \
        -H "Authorization: Token $SYTEX_TOKEN" \
        -H "Organization: $SYTEX_ORG_ID" \
        -H "Accept: application/json"
}

# URL encode helper
url_encode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"
}

# Build query string from key=value pairs
build_query() {
    local query=""
    for param in "$@"; do
        [[ -n "$query" ]] && query="${query}&"
        query="${query}${param}"
    done
    echo "$query"
}

# === TASKS ===

cmd_tasks() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --status) params+=("status=$2"); shift 2 ;;
            --project) params+=("project=$2"); shift 2 ;;
            --assigned-staff) params+=("assigned_staff=$2"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/task/${query}"
}

cmd_task() {
    local task_id="$1"
    [[ -z "$task_id" ]] && echo "Error: task ID required" && exit 1
    api_get "/task/${task_id}/"
}

cmd_task_update() {
    local task_id="$1"
    local data="$2"
    [[ -z "$task_id" ]] && echo "Error: task ID required" && exit 1
    [[ -z "$data" ]] && echo "Error: JSON data required" && exit 1
    api_patch "/task/${task_id}/" "$data"
}

cmd_task_status() {
    local code="$1"
    local status="$2"
    [[ -z "$code" || -z "$status" ]] && echo "Error: code and status required" && exit 1
    api_post "/import/TaskImport/go/" "{\"code\": \"$code\", \"status_step\": \"$status\"}"
}

cmd_task_create() {
    local data="$1"
    [[ -z "$data" ]] && echo "Error: JSON data required" && exit 1
    api_post "/task/" "$data"
}

# === PROJECTS ===

cmd_projects() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/project/${query}"
}

cmd_project() {
    local project_id="$1"
    [[ -z "$project_id" ]] && echo "Error: project ID required" && exit 1
    api_get "/project/${project_id}/"
}

# === SITES ===

cmd_sites() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --status) params+=("status=$2"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/site/${query}"
}

cmd_site() {
    local site_id="$1"
    [[ -z "$site_id" ]] && echo "Error: site ID required" && exit 1
    api_get "/site/${site_id}/"
}

# === MATERIALS ===

cmd_materials() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/material/${query}"
}

cmd_material_ops() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --status) params+=("status=$2"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/materialoperation/${query}"
}

cmd_mo_status() {
    local code="$1"
    local status="$2"
    [[ -z "$code" || -z "$status" ]] && echo "Error: code and status required" && exit 1
    api_post "/import/SimpleOperationImport/go/" "{\"code\": \"$code\", \"status_step\": \"$status\"}"
}

cmd_mo_add_item() {
    local data="$1"
    [[ -z "$data" ]] && echo "Error: JSON data required" && exit 1
    api_post "/import/SimpleOperationItemImport/go/" "$data"
}

# === FORMS ===

cmd_forms() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --status) params+=("status=$2"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/form/${query}"
}

cmd_form() {
    local form_id="$1"
    [[ -z "$form_id" ]] && echo "Error: form ID required" && exit 1
    api_get "/form/${form_id}/"
}

# === STAFF ===

cmd_staff() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) params+=("limit=$2"); shift 2 ;;
            --offset) params+=("offset=$2"); shift 2 ;;
            --q) params+=("q=$(url_encode "$2")"); shift 2 ;;
            --ordering) params+=("ordering=$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    local query=$(build_query "${params[@]}")
    [[ -n "$query" ]] && query="?$query"
    api_get "/staff/${query}"
}

cmd_user_roles() {
    local search="$1"
    [[ -z "$search" ]] && echo "Error: search term required" && exit 1

    # Use last word (usually surname) for better search results
    local search_term="${search##* }"

    # Search staff by name
    local staff_result=$(api_get "/staff/?q=$(url_encode "$search_term")&limit=10")

    # Find user matching all words in search term
    local user_id=$(echo "$staff_result" | jq -r --arg search "$search" '
        ($search | ascii_downcase | gsub("\\s+"; " ") | split(" ")) as $words |
        .results[] |
        select(
            .name as $name |
            ($name | ascii_downcase | gsub("\\s+"; " ")) as $normalized |
            all($words[]; . as $word | $normalized | contains($word))
        ) |
        .related_user_id
    ' | head -1)

    # Fallback to first result if no match
    [[ -z "$user_id" ]] && user_id=$(echo "$staff_result" | jq -r '.results[0].related_user_id // empty')

    [[ -z "$user_id" ]] && echo "Error: user not found for '$search'" && exit 1

    # Get user roles
    api_get "/userrole/?user=${user_id}&limit=100"
}

# === AUTOMATIONS ===

cmd_automation() {
    local uuid="$1"
    local data="$2"
    [[ -z "$uuid" ]] && echo "Error: automation UUID required" && exit 1
    [[ -z "$data" ]] && data="{}"
    api_post "/automation/${uuid}/execute/" "$data"
}

# === GENERIC ===

cmd_get() {
    local endpoint="$1"
    [[ -z "$endpoint" ]] && echo "Error: endpoint required" && exit 1
    api_get "$endpoint"
}

cmd_post() {
    local endpoint="$1"
    local data="$2"
    [[ -z "$endpoint" ]] && echo "Error: endpoint required" && exit 1
    [[ -z "$data" ]] && data="{}"
    api_post "$endpoint" "$data"
}

cmd_put() {
    local endpoint="$1"
    local data="$2"
    [[ -z "$endpoint" || -z "$data" ]] && echo "Error: endpoint and data required" && exit 1
    api_put "$endpoint" "$data"
}

cmd_patch() {
    local endpoint="$1"
    local data="$2"
    [[ -z "$endpoint" || -z "$data" ]] && echo "Error: endpoint and data required" && exit 1
    api_patch "$endpoint" "$data"
}

cmd_delete() {
    local endpoint="$1"
    [[ -z "$endpoint" ]] && echo "Error: endpoint required" && exit 1
    api_delete "$endpoint"
}

# === MAIN ===

show_help() {
    echo "Sytex API CLI"
    echo ""
    echo "TASKS:"
    echo "  tasks [--limit N] [--q QUERY] [--status ID] [--project ID]"
    echo "  task <id>                          Get task details"
    echo "  task-update <id> <json>            Update task (PATCH)"
    echo "  task-status <code> <status>        Update task status by code"
    echo "  task-create <json>                 Create new task"
    echo ""
    echo "PROJECTS:"
    echo "  projects [--limit N] [--q QUERY]   List projects"
    echo "  project <id>                       Get project details"
    echo ""
    echo "SITES:"
    echo "  sites [--limit N] [--q QUERY]      List sites"
    echo "  site <id>                          Get site details"
    echo ""
    echo "MATERIALS:"
    echo "  materials [--limit N] [--q QUERY]  List materials"
    echo "  material-ops [--limit N]           List material operations"
    echo "  mo-status <code> <status>          Update MO status"
    echo "  mo-add-item <json>                 Add item to MO"
    echo ""
    echo "FORMS:"
    echo "  forms [--limit N] [--q QUERY]      List forms"
    echo "  form <id>                          Get form details"
    echo ""
    echo "STAFF:"
    echo "  staff [--limit N] [--q QUERY]      List staff members"
    echo "  user-roles <name>                  Get roles for a user by name"
    echo ""
    echo "AUTOMATIONS:"
    echo "  automation <uuid> [json]           Execute automation"
    echo ""
    echo "GENERIC (for any endpoint):"
    echo "  get <endpoint>                     GET request"
    echo "  post <endpoint> [json]             POST request"
    echo "  put <endpoint> <json>              PUT request"
    echo "  patch <endpoint> <json>            PATCH request"
    echo "  delete <endpoint>                  DELETE request"
    echo ""
    echo "COMMON FLAGS:"
    echo "  --limit N       Results per page"
    echo "  --offset N      Skip first N results"
    echo "  --q QUERY       Search text"
    echo "  --ordering FIELD  Sort by field (prefix with - for desc)"
}

case "$1" in
    tasks) shift; cmd_tasks "$@" ;;
    task) cmd_task "$2" ;;
    task-update) cmd_task_update "$2" "$3" ;;
    task-status) cmd_task_status "$2" "$3" ;;
    task-create) cmd_task_create "$2" ;;
    projects) shift; cmd_projects "$@" ;;
    project) cmd_project "$2" ;;
    sites) shift; cmd_sites "$@" ;;
    site) cmd_site "$2" ;;
    materials) shift; cmd_materials "$@" ;;
    material-ops) shift; cmd_material_ops "$@" ;;
    mo-status) cmd_mo_status "$2" "$3" ;;
    mo-add-item) cmd_mo_add_item "$2" ;;
    forms) shift; cmd_forms "$@" ;;
    form) cmd_form "$2" ;;
    staff) shift; cmd_staff "$@" ;;
    user-roles) cmd_user_roles "$2" ;;
    automation) cmd_automation "$2" "$3" ;;
    get) cmd_get "$2" ;;
    post) cmd_post "$2" "$3" ;;
    put) cmd_put "$2" "$3" ;;
    patch) cmd_patch "$2" "$3" ;;
    delete) cmd_delete "$2" ;;
    *) show_help; exit 1 ;;
esac
