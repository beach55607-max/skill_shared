# Adapter: Browser Extension

Use this adapter for browser or Chromium extension work, especially manifest, background, storage, and message-passing changes.

## Ownership

This runtime usually owns:

- manifest configuration
- background or service worker logic
- content-script behavior
- extension storage and message routing

## Example Scenario

Example: the extension needs a new host permission and a new background message branch to fetch data from another domain.
This adapter is primary when manifest permissions, background behavior, storage, and message routing must stay consistent as one runtime boundary.

## Protected Surfaces

Treat these as contract-sensitive:

- `manifest.json`
- permissions and host access
- message passing between extension contexts
- storage schema and migration
- external API auth usage inside the extension runtime

## Validation

- start with the narrowest storage, routing, or background-focused test
- run repo-standard lint and test
- run build or packaging verification
- add runtime smoke checks when permissions or host access change

## Stop Conditions

Escalate when the task changes:

- permissions or `host_permissions`
- storage schema
- background message routing
- external API auth or token handling
