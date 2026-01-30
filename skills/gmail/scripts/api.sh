#!/bin/bash
# Gmail IMAP operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$CONFIG_DIR/.env"

[[ ! -f "$CONFIG_FILE" ]] && echo "Error: Not configured. Create $CONFIG_FILE with GMAIL_EMAIL and GMAIL_APP_PASSWORD" && exit 1

source "$CONFIG_FILE"

[[ -z "$GMAIL_EMAIL" ]] && echo "Error: GMAIL_EMAIL not configured" && exit 1
[[ -z "$GMAIL_APP_PASSWORD" ]] && echo "Error: GMAIL_APP_PASSWORD not configured" && exit 1

run_python() {
    python3 -c "
import imaplib
import email
from email.header import decode_header
import sys

EMAIL = '$GMAIL_EMAIL'
PASSWORD = '$GMAIL_APP_PASSWORD'

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

# Main dispatcher
case "$1" in
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
        echo "Gmail IMAP Commands"
        echo ""
        echo "  PROFILE:"
        echo "  me                            - Get account info"
        echo "  labels                        - List all folders/labels"
        echo ""
        echo "  MESSAGES:"
        echo "  list [flags]                  - List messages"
        echo "       --label <folder>         - Folder (INBOX, [Gmail]/Sent, etc)"
        echo "       --limit <n>              - Max results (default: 10)"
        echo "       --unread                 - Only unread messages"
        echo "  get <messageId> [flags]       - Read full message"
        echo "       --all                    - Read from All Mail"
        echo "       --trash                  - Read from Trash"
        echo "       --label <folder>         - Read from specific folder"
        echo "  search <query> [flags]        - Search messages"
        echo "       --limit <n>              - Max results (default: 10)"
        echo "       --oldest                 - Show oldest first"
        echo "       --all                    - Search in All Mail (includes archived)"
        echo "       --trash                  - Search in Trash"
        echo "       --label <folder>         - Search in specific folder"
        echo ""
        echo "Search query examples:"
        echo "  is:unread                     - Unread messages"
        echo "  is:starred                    - Starred messages"
        echo "  from:someone@example.com      - From specific sender"
        echo "  to:someone@example.com        - To specific recipient"
        echo "  subject:meeting               - Subject contains 'meeting'"
        echo "  before:2024/01/15             - Before date"
        echo "  after:2024/01/15              - After date"
        echo "  older_than:7d                 - Older than 7 days (d/m/y)"
        echo "  newer_than:1m                 - Newer than 1 month"
        echo "  <any text>                    - Search in body"
        echo ""
        echo "Examples:"
        echo "  search older_than:1y --oldest --limit 20"
        echo "  search from:boss@company.com before:2023/06/01"
        exit 1
        ;;
esac
