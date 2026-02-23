#!/bin/bash
# Gmail IMAP operations - Multi-account support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="$(basename "$(dirname "$SCRIPT_DIR")")"
CONFIG_FILE="$HOME/.agent-skills/$SKILL_NAME/.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse global --account flag first
SELECTED_ACCOUNT=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --account|-a)
            SELECTED_ACCOUNT="$2"
            shift 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${ARGS[@]}"

load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
}

# Get account config value
get_account_config() {
    local account="$1"
    local field="$2"
    local name_upper=$(echo "$account" | tr '[:lower:]-' '[:upper:]_')
    local var_name="GMAIL_ACCOUNT_${name_upper}_${field}"
    echo "${!var_name:-}"
}

# Get list of configured accounts
get_configured_accounts() {
    [[ ! -f "$CONFIG_FILE" ]] && return
    grep -o 'GMAIL_ACCOUNT_[A-Z0-9_]*_EMAIL' "$CONFIG_FILE" 2>/dev/null | \
        sed 's/^GMAIL_ACCOUNT_//' | \
        sed 's/_EMAIL$//' | \
        tr '[:upper:]_' '[:lower:]-' | \
        sort -u
}

# Check for legacy single-account format
has_legacy_config() {
    [[ -f "$CONFIG_FILE" ]] && grep -q '^GMAIL_EMAIL=' "$CONFIG_FILE" 2>/dev/null
}

# Resolve which account to use
resolve_account() {
    # Explicit selection
    if [[ -n "$SELECTED_ACCOUNT" ]]; then
        echo "$SELECTED_ACCOUNT"
        return
    fi

    # Default account setting
    load_config
    if [[ -n "${GMAIL_DEFAULT_ACCOUNT:-}" ]]; then
        echo "$GMAIL_DEFAULT_ACCOUNT"
        return
    fi

    # Legacy single-account format
    if has_legacy_config; then
        echo "default"
        return
    fi

    # First configured account
    get_configured_accounts | head -1
}

# Get credentials for current account
get_credentials() {
    local account="$1"

    # Legacy format support
    if [[ "$account" == "default" ]] && has_legacy_config; then
        load_config
        CURRENT_EMAIL="$GMAIL_EMAIL"
        CURRENT_PASSWORD="$GMAIL_APP_PASSWORD"
        return
    fi

    load_config
    CURRENT_EMAIL=$(get_account_config "$account" "EMAIL")
    CURRENT_PASSWORD=$(get_account_config "$account" "APP_PASSWORD")
}

ensure_credentials() {
    local account=$(resolve_account)
    [[ -z "$account" ]] && echo "Error: No accounts configured. Add GMAIL_ACCOUNT_<name>_EMAIL and GMAIL_ACCOUNT_<name>_APP_PASSWORD to .env" && exit 1

    get_credentials "$account"

    [[ -z "$CURRENT_EMAIL" ]] && echo "Error: GMAIL_ACCOUNT_${account^^}_EMAIL not configured" && exit 1
    [[ -z "$CURRENT_PASSWORD" ]] && echo "Error: GMAIL_ACCOUNT_${account^^}_APP_PASSWORD not configured" && exit 1
}

run_python() {
    ensure_credentials
    python3 -c "
import imaplib
import email
from email.header import decode_header
import sys

EMAIL = '$CURRENT_EMAIL'
PASSWORD = '$CURRENT_PASSWORD'

def connect():
    mail = imaplib.IMAP4_SSL('imap.gmail.com')
    mail.login(EMAIL, PASSWORD)
    return mail

def decode_str(s):
    if s is None:
        return ''
    decoded = decode_header(s)
    result = []
    for part, charset in decoded:
        if isinstance(part, bytes):
            result.append(part.decode(charset or 'utf-8', errors='replace'))
        else:
            result.append(part)
    return ''.join(result)

def get_body(msg):
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            if content_type == 'text/plain':
                payload = part.get_payload(decode=True)
                if payload:
                    charset = part.get_content_charset() or 'utf-8'
                    return payload.decode(charset, errors='replace')
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            charset = msg.get_content_charset() or 'utf-8'
            return payload.decode(charset, errors='replace')
    return ''

$1
"
}

# === ACCOUNTS ===

cmd_accounts() {
    load_config
    echo -e "${BLUE}Configured Gmail accounts:${NC}"
    echo ""

    local current=$(resolve_account)
    local found=false

    # Check legacy config
    if has_legacy_config; then
        found=true
        local marker=""
        [[ "$current" == "default" ]] && marker=" ${GREEN}(active)${NC}"
        echo -e "  ${YELLOW}●${NC} default (legacy)$marker"
        echo -e "    Email: $GMAIL_EMAIL"
        echo ""
    fi

    # List multi-account configs
    while IFS= read -r account; do
        [[ -z "$account" ]] && continue
        found=true
        local marker=""
        [[ "$account" == "$current" ]] && marker=" ${GREEN}(active)${NC}"
        local account_email=$(get_account_config "$account" "EMAIL")

        echo -e "  ${YELLOW}●${NC} $account$marker"
        echo -e "    Email: $account_email"
        echo ""
    done < <(get_configured_accounts)

    if [[ "$found" == "false" ]]; then
        echo -e "  ${RED}No accounts configured.${NC}"
        echo ""
        echo "Add to .env file:"
        echo "  GMAIL_ACCOUNT_<name>_EMAIL=\"your@gmail.com\""
        echo "  GMAIL_ACCOUNT_<name>_APP_PASSWORD=\"your-app-password\""
    fi
}

cmd_me() {
    run_python "
mail = connect()
print(f'Email: {EMAIL}')
mail.select('INBOX')
status, messages = mail.search(None, 'ALL')
total = len(messages[0].split()) if messages[0] else 0
status, unseen = mail.search(None, 'UNSEEN')
unread = len(unseen[0].split()) if unseen[0] else 0
print(f'Total messages: {total}')
print(f'Unread: {unread}')
mail.logout()
"
}

cmd_labels() {
    run_python "
mail = connect()
status, folders = mail.list()
for folder in folders:
    decoded = folder.decode()
    parts = decoded.split(' \"/\" ')
    if len(parts) > 1:
        name = parts[1].strip('\"')
        print(name)
mail.logout()
"
}

cmd_list() {
    local folder="INBOX"
    local limit="10"
    local search_criteria="ALL"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --label) folder="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            --unread) search_criteria="UNSEEN"; shift ;;
            *) shift ;;
        esac
    done

    run_python "
mail = connect()
mail.select('$folder')
status, messages = mail.search(None, '$search_criteria')
msg_ids = messages[0].split()
msg_ids = msg_ids[-$limit:] if len(msg_ids) > $limit else msg_ids
msg_ids = msg_ids[::-1]

if not msg_ids:
    print('No messages found.')
    mail.logout()
    sys.exit(0)

for msg_id in msg_ids:
    status, data = mail.fetch(msg_id, '(RFC822.HEADER)')
    raw = data[0][1]
    msg = email.message_from_bytes(raw)

    from_addr = decode_str(msg.get('From', 'Unknown'))
    subject = decode_str(msg.get('Subject', '(no subject)'))
    date = msg.get('Date', 'Unknown')

    print(f'[{msg_id.decode()}]')
    print(f'  From: {from_addr}')
    print(f'  Subject: {subject}')
    print(f'  Date: {date}')
    print()

mail.logout()
"
}

cmd_get() {
    local msg_id=""
    local label="INBOX"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all) label="[Gmail]/All Mail"; shift ;;
            --trash) label="[Gmail]/Trash"; shift ;;
            --label) label="$2"; shift 2 ;;
            *) [[ -z "$msg_id" ]] && msg_id="$1"; shift ;;
        esac
    done

    [[ -z "$msg_id" ]] && echo "Usage: gmail get <message_id> [--all] [--trash] [--label FOLDER]" && exit 1

    run_python "
mail = connect()
mail.select('\"$label\"')
status, data = mail.fetch(b'$msg_id', '(RFC822)')

if status != 'OK':
    print('Error: Message not found')
    mail.logout()
    sys.exit(1)

raw = data[0][1]
msg = email.message_from_bytes(raw)

from_addr = decode_str(msg.get('From', 'Unknown'))
to_addr = decode_str(msg.get('To', 'Unknown'))
subject = decode_str(msg.get('Subject', '(no subject)'))
date = msg.get('Date', 'Unknown')

print('=' * 60)
print(f'From: {from_addr}')
print(f'To: {to_addr}')
print(f'Subject: {subject}')
print(f'Date: {date}')
print('=' * 60)
print()
print(get_body(msg))

mail.logout()
"
}

cmd_search() {
    local query=""
    local limit="10"
    local oldest="false"
    local label="INBOX"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) limit="$2"; shift 2 ;;
            --oldest) oldest="true"; shift ;;
            --label) label="$2"; shift 2 ;;
            --all) label="[Gmail]/All Mail"; shift ;;
            --trash) label="[Gmail]/Trash"; shift ;;
            *) [[ -z "$query" ]] && query="$1" || query="$query $1"; shift ;;
        esac
    done

    [[ -z "$query" ]] && echo "Usage: gmail search <query> [--limit N] [--oldest] [--all] [--trash] [--label FOLDER]" && exit 1

    run_python "
from datetime import datetime, timedelta
import re

query = '''$query'''
imap_parts = []

# Parse query terms
terms = query.split()
i = 0
while i < len(terms):
    term = terms[i]

    if term == 'is:unread':
        imap_parts.append('UNSEEN')
    elif term == 'is:starred':
        imap_parts.append('FLAGGED')
    elif term.startswith('from:'):
        imap_parts.append(f'FROM \"{term[5:]}\"')
    elif term.startswith('to:'):
        imap_parts.append(f'TO \"{term[3:]}\"')
    elif term.startswith('subject:'):
        imap_parts.append(f'SUBJECT \"{term[8:]}\"')
    elif term.startswith('before:'):
        # Format: before:2024/01/15 or before:2024-01-15
        date_str = term[7:].replace('-', '/')
        dt = datetime.strptime(date_str, '%Y/%m/%d')
        imap_date = dt.strftime('%d-%b-%Y')
        imap_parts.append(f'BEFORE {imap_date}')
    elif term.startswith('after:'):
        date_str = term[6:].replace('-', '/')
        dt = datetime.strptime(date_str, '%Y/%m/%d')
        imap_date = dt.strftime('%d-%b-%Y')
        imap_parts.append(f'SINCE {imap_date}')
    elif term.startswith('older_than:'):
        # Format: older_than:7d, older_than:2m, older_than:1y
        val = term[11:]
        match = re.match(r'(\d+)([dmy])', val)
        if match:
            num, unit = int(match.group(1)), match.group(2)
            if unit == 'd':
                dt = datetime.now() - timedelta(days=num)
            elif unit == 'm':
                dt = datetime.now() - timedelta(days=num*30)
            elif unit == 'y':
                dt = datetime.now() - timedelta(days=num*365)
            imap_date = dt.strftime('%d-%b-%Y')
            imap_parts.append(f'BEFORE {imap_date}')
    elif term.startswith('newer_than:'):
        val = term[11:]
        match = re.match(r'(\d+)([dmy])', val)
        if match:
            num, unit = int(match.group(1)), match.group(2)
            if unit == 'd':
                dt = datetime.now() - timedelta(days=num)
            elif unit == 'm':
                dt = datetime.now() - timedelta(days=num*30)
            elif unit == 'y':
                dt = datetime.now() - timedelta(days=num*365)
            imap_date = dt.strftime('%d-%b-%Y')
            imap_parts.append(f'SINCE {imap_date}')
    else:
        imap_parts.append(f'TEXT \"{term}\"')
    i += 1

imap_query = ' '.join(imap_parts) if imap_parts else 'ALL'

mail = connect()
mail.select('\"$label\"')
status, messages = mail.search(None, imap_query)
msg_ids = messages[0].split()

oldest_first = '$oldest' == 'true'
if oldest_first:
    msg_ids = msg_ids[:$limit]
else:
    msg_ids = msg_ids[-$limit:] if len(msg_ids) > $limit else msg_ids
    msg_ids = msg_ids[::-1]

if not msg_ids:
    print(f'No messages found for: {query}')
    mail.logout()
    sys.exit(0)

print(f'Found {len(messages[0].split())} total, showing {len(msg_ids)}:')
print()

for msg_id in msg_ids:
    status, data = mail.fetch(msg_id, '(RFC822.HEADER)')
    raw = data[0][1]
    msg = email.message_from_bytes(raw)

    from_addr = decode_str(msg.get('From', 'Unknown'))
    subject = decode_str(msg.get('Subject', '(no subject)'))
    date = msg.get('Date', 'Unknown')

    print(f'[{msg_id.decode()}]')
    print(f'  From: {from_addr}')
    print(f'  Subject: {subject}')
    print(f'  Date: {date}')
    print()

mail.logout()
"
}

# === HELP ===

show_help() {
    echo "Gmail IMAP Commands - Multi-account"
    echo ""
    echo "GLOBAL FLAGS:"
    echo "  --account, -a <name>              Select account (default: first configured)"
    echo ""
    echo "SETUP:"
    echo "  accounts                          List configured accounts"
    echo ""
    echo "PROFILE:"
    echo "  me                                Get account info"
    echo "  labels                            List all folders/labels"
    echo ""
    echo "MESSAGES:"
    echo "  list [flags]                      List messages"
    echo "       --label <folder>             Folder (INBOX, [Gmail]/Sent, etc)"
    echo "       --limit <n>                  Max results (default: 10)"
    echo "       --unread                     Only unread messages"
    echo "  get <messageId> [flags]           Read full message"
    echo "       --all                        Read from All Mail"
    echo "       --trash                      Read from Trash"
    echo "       --label <folder>             Read from specific folder"
    echo "  search <query> [flags]            Search messages"
    echo "       --limit <n>                  Max results (default: 10)"
    echo "       --oldest                     Show oldest first"
    echo "       --all                        Search in All Mail (includes archived)"
    echo "       --trash                      Search in Trash"
    echo "       --label <folder>             Search in specific folder"
    echo ""
    echo "Search query examples:"
    echo "  is:unread                         Unread messages"
    echo "  is:starred                        Starred messages"
    echo "  from:someone@example.com          From specific sender"
    echo "  to:someone@example.com            To specific recipient"
    echo "  subject:meeting                   Subject contains 'meeting'"
    echo "  before:2024/01/15                 Before date"
    echo "  after:2024/01/15                  After date"
    echo "  older_than:7d                     Older than 7 days (d/m/y)"
    echo "  newer_than:1m                     Newer than 1 month"
    echo "  <any text>                        Search in body"
    echo ""
    echo "Examples:"
    echo "  gmail accounts"
    echo "  gmail --account work list --unread"
    echo "  gmail --account personal search from:boss@company.com"
    echo "  gmail search older_than:1y --oldest --limit 20"
}

# Main dispatcher
case "$1" in
    accounts)
        cmd_accounts
        ;;
    me)
        cmd_me
        ;;
    labels)
        cmd_labels
        ;;
    list)
        shift
        cmd_list "$@"
        ;;
    get)
        shift
        cmd_get "$@"
        ;;
    search)
        shift
        cmd_search "$@"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
