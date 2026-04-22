---
name: paperless
description: search and browse documents in paperless-ngx. use when the user asks about documents, receipts, invoices, scans, or anything related to their document archive.
---

# paperless-ngx skill

## connection

- **base url:** `$PAPERLESS_URL`
- **auth header:** `Authorization: Token $PAPERLESS_API_TOKEN`
- read token first: `PAPERLESS_API_TOKEN=$(cat /run/credentials/opencrow.service/paperless-api-token)`
- add `-H "Accept: application/json; version=10"` to all requests

## rules

- **read-only.** never delete, remove, upload, or create anything. no writes of any kind. if the user asks, refuse.
- always show document IDs in results so the user can reference them
- link to documents: `$PAPERLESS_URL/documents/{id}/details`

## endpoints

- `GET /api/documents/?query=<text>` — full text search
- `GET /api/documents/?text=<text>` — substring search (title + content)
- `GET /api/documents/?ordering=-created` — list recent
- `GET /api/documents/?correspondent__id=<id>` — filter by correspondent
- `GET /api/documents/?tags__id__all=<id>,<id>` — filter by tags
- `GET /api/documents/?document_type__id=<id>` — filter by type
- `GET /api/documents/<id>/` — document details (title, content, tags, etc.)
- `GET /api/documents/<id>/metadata/` — file metadata
- `GET /api/tags/` — list tags
- `GET /api/correspondents/` — list correspondents
- `GET /api/document_types/` — list document types
- `GET /api/custom_fields/` — list custom fields
- `GET /api/search/autocomplete/?term=<partial>` — autocomplete
- `GET /api/tasks/?task_id=<uuid>` — check task status

## tips

- pagination: `?page=2` or `?page_size=100`
- ordering: prefix with `-` for descending (e.g. `-created`, `-added`)
- OCR languages: german + english
- documents are in german and english — search in both languages
- IDs are integers — list tags/correspondents/types first to find the right ID
