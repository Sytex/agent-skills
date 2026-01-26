# Pipedrive Skill

CLI tool for interacting with the Pipedrive CRM API using OAuth2.

## Setup

1. Go to [Pipedrive Developer Hub](https://developers.pipedrive.com/) and create an app
2. Get your Client ID and Client Secret
3. Set the redirect URI to: `https://oauth.pipedrive.com/callback`
4. Run the auth command:
   ```bash
   ~/.claude/skills/pipedrive/pipedrive auth
   ```
5. Follow the prompts to authorize

## Usage

```bash
~/.claude/skills/pipedrive/pipedrive <command> [args]
```

Run without arguments to see available commands.

Check authentication status:
```bash
~/.claude/skills/pipedrive/pipedrive status
```

## API Reference

- [Pipedrive API Documentation](https://developers.pipedrive.com/docs/api/v1)
- [OAuth2 Authorization](https://pipedrive.readme.io/docs/marketplace-oauth-authorization)
