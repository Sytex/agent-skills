#!/bin/bash
# Gmail IMAP operations

CONFIG_DIR="$HOME/.claude/skills/gmail"
CONFIG_FILE="$CONFIG_DIR/.env"

[[ ! -f "$CONFIG_FILE" ]] && echo "Error: Not configured. Run: ~/.claude/skills/gmail/config.sh setup" && exit 1

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
    local msg_id="$1"

    [[ -z "$msg_id" ]] && echo "Usage: gmail get <message_id>" && exit 1

    run_python "
mail = connect()
mail.select('INBOX')
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
    local query="$1"
    local limit="${2:-10}"

    [[ -z "$query" ]] && echo "Usage: gmail search <query> [limit]" && exit 1

    # Convert Gmail-style queries to IMAP
    local imap_query=""

    if [[ "$query" == "is:unread" ]]; then
        imap_query="UNSEEN"
    elif [[ "$query" == is:starred ]]; then
        imap_query="FLAGGED"
    elif [[ "$query" =~ ^from: ]]; then
        local from_addr="${query#from:}"
        imap_query="FROM \"$from_addr\""
    elif [[ "$query" =~ ^to: ]]; then
        local to_addr="${query#to:}"
        imap_query="TO \"$to_addr\""
    elif [[ "$query" =~ ^subject: ]]; then
        local subj="${query#subject:}"
        imap_query="SUBJECT \"$subj\""
    else
        # Generic text search
        imap_query="TEXT \"$query\""
    fi

    run_python "
mail = connect()
mail.select('INBOX')
status, messages = mail.search(None, '$imap_query')
msg_ids = messages[0].split()
msg_ids = msg_ids[-$limit:] if len(msg_ids) > $limit else msg_ids
msg_ids = msg_ids[::-1]

if not msg_ids:
    print('No messages found for: $query')
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
        cmd_get "$2"
        ;;
    search)
        cmd_search "$2" "$3"
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
        echo "  get <messageId>               - Read full message"
        echo "  search <query> [limit]        - Search messages"
        echo ""
        echo "Search query examples:"
        echo "  is:unread                     - Unread messages"
        echo "  is:starred                    - Starred messages"
        echo "  from:someone@example.com      - From specific sender"
        echo "  to:someone@example.com        - To specific recipient"
        echo "  subject:meeting               - Subject contains 'meeting'"
        echo "  <any text>                    - Search in body"
        exit 1
        ;;
esac
