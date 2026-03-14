"""
Oompa-Loompa Template

Copy this template and customize for your specific use case.
"""

import requests

# === DISCORD (optional) ===
DISCORD_MESSAGE_TEMPLATE = """# {script_name} Progress

`{instance}` {part_label}

{bar} **{pct}%**

{emoji} **Status:** {status}
📊 **Progress:** {total}/{max_items}
✅ **Processed:** {processed}
⏭️ **Skipped:** {skipped}
❌ **Errors:** {errors}"""


# === MAIN CLASS ===
class OompaLoompa:
    def __init__(self, instance_name: str = "default", discord_webhook_url: str = ""):
        self.instance_name = instance_name
        self.discord_webhook_url = discord_webhook_url
        self.discord_message_id = None

    # --- Discord helpers ---
    def _progress_bar(self, pct, width=20):
        filled = int(width * pct / 100)
        return "▓" * filled + "░" * (width - filled)

    def _discord_message(
        self, part_label, total, max_items, processed, skipped, errors, status="running"
    ):
        pct = (total * 100 // max_items) if max_items else 0
        bar = self._progress_bar(pct)
        emoji = "🔄" if status == "running" else "✅" if status == "done" else "❌"
        return DISCORD_MESSAGE_TEMPLATE.format(
            script_name="SCRIPT_NAME",  # TODO: Update
            instance=self.instance_name.upper(),
            part_label=part_label or "",
            bar=bar,
            pct=pct,
            emoji=emoji,
            status=status.upper(),
            total=total,
            max_items=max_items or "?",
            processed=processed,
            skipped=skipped,
            errors=errors,
        )

    def _discord_send(self, content):
        if not self.discord_webhook_url:
            return
        resp = requests.post(
            f"{self.discord_webhook_url}?wait=true", json={"content": content}
        )
        if resp.ok:
            self.discord_message_id = resp.json().get("id")

    def _discord_update(self, content):
        if not self.discord_webhook_url or not self.discord_message_id:
            return
        requests.patch(
            f"{self.discord_webhook_url}/messages/{self.discord_message_id}",
            json={"content": content},
        )

    # --- Main logic ---
    def count(self):
        """Count total items to process."""
        # TODO: Implement
        return 0

    def run(self, max_items=None, dry_run=False, part_label=None):
        """
        Run the oompa-loompa.

        Args:
            max_items: Stop after processing this many items (None = no limit)
            dry_run: Preview without making changes
            part_label: Label for progress output (e.g., 'P1', 'P2')
        """
        label = f"[{part_label}] " if part_label else ""
        print(f"{label}Starting...")
        if dry_run:
            print(f"{label}DRY RUN - no changes will be made")
        if max_items:
            print(f"{label}Will process up to {max_items} items")

        total = processed = skipped = errors = 0

        # Send initial Discord message
        self._discord_send(
            self._discord_message(part_label, 0, max_items, 0, 0, 0, "starting")
        )

        # TODO: Implement iteration logic
        # Example:
        # for item in self.get_items():
        #     total += 1
        #     if max_items and total > max_items:
        #         break
        #
        #     if self.should_skip(item):
        #         skipped += 1
        #         continue
        #
        #     if dry_run:
        #         processed += 1
        #         continue
        #
        #     try:
        #         self.process_item(item)
        #         processed += 1
        #     except Exception as e:
        #         errors += 1
        #         print(f'{label}Error: {e}')
        #
        #     # Progress every 100 items
        #     if total % 100 == 0:
        #         pct = f' ({total*100//max_items}%)' if max_items else ''
        #         print(f'{label}Progress: {total}/{max_items or "?"}{pct}')
        #         self._discord_update(...)

        # Final Discord update
        self._discord_update(
            self._discord_message(
                part_label, total, max_items, processed, skipped, errors, "done"
            )
        )
        print(
            f"\n{label}Done! Total={total}, Processed={processed}, "
            f"Skipped={skipped}, Errors={errors}"
        )


# === ENTRY POINT ===
oompa = OompaLoompa()
print(
    """
=== OOMPA-LOOMPA: SCRIPT_NAME ===

Usage:
  oompa.count()              # Count total items
  oompa.run()                # Run all
  oompa.run(dry_run=True)    # Preview without changes
  oompa.run(max_items=100)   # Process only 100 items

Discord notifications:
  oompa.discord_webhook_url = 'https://discord.com/api/webhooks/...'

To copy this script to a pod:
  kubectl cp local_scripts/SCRIPT_NAME.py <namespace>/<pod>:/tmp/oompa.py

To run in the pod:
  python manage.py shell_plus
  >>> exec(open('/tmp/oompa.py').read())
  >>> oompa.discord_webhook_url = 'https://...'  # optional
  >>> oompa.run()
"""
)
