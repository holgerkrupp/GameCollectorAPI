Client side to talk to the Server hosting some of Game Collectors data.

## Prices API

Prices are stored in the server's `PriceGuide` table — the imported PriceCharting
price guide. A "release" is one row of it, and the release id in every route is
that row's id, which is the PriceCharting product id it was imported under.

Releases can be looked up by:

- EAN / UPC (`PriceGuide.upc`)
- PriceCharting product id (`PriceGuide.id`) — send it as `priceChartingId`
- IGDB id, resolved through `EANkeys.sourceID`, when it reaches exactly one
  priced product

Every response is marked as coming from that table:

- `source_name = "PriceGuideLegacy"`
- `is_legacy_seed = true`
- `observed_at = null`

What the table cannot hold, and how the API handles it:

- **No history.** One price per condition; a write overwrites the column. There
  is no `/history` endpoint — see below.
- **No timestamps.** `observed_at` is always null, which also stops clients
  treating an old import as a current price.
- **No currency column.** The guide is in US dollars, so `USD` is the only
  currency accepted on write, and writes in any other currency are rejected
  rather than misfiled as dollars.
- **Conditions are `loose`, `cib` and `new`.** `graded` is accepted and dropped.
- **No region or variant columns.** `region_code` is derived from `consolename`,
  which is where PriceCharting records it (`PAL …`, `JP …`).

A price for a product the guide does not have yet is inserted under its
PriceCharting product id. Without that id there is nothing to key the row on, so
the write is skipped rather than inventing an id — every lookup here depends on
`PriceGuide.id` meaning what PriceCharting says it means.

Base URL:

```text
https://levelcomplete.de/api/v3a/
```

All requests need an `APIkey` header.

Example:

```text
APIkey: YOUR_API_KEY
Content-Type: application/json
Accept: application/json
```

### Create a price entry

`POST /prices`

Creates a new historical price row. If the release does not exist yet, it is created and linked to the supplied identifiers.

Example request:

```bash
curl -X POST "https://levelcomplete.de/api/v3a/prices" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "release": {
      "name": "The Legend of Zelda: Twilight Princess",
      "platform": "Nintendo GameCube",
      "region": "eu",
      "variant": "Player'\''s Choice",
      "identifiers": [
        {
          "type": "ean",
          "value": "045496430122",
          "isPrimary": true
        },
        {
          "type": "igdb",
          "value": "1009",
          "sourceName": "IGDB"
        }
      ]
    },
    "price": {
      "condition": "cib",
      "currency": "EUR",
      "amount": 89.99,
      "observedAt": "2026-06-30T10:45:00Z",
      "source": "manual"
    }
  }'
```

Minimal example using only EAN:

```bash
curl -X POST "https://levelcomplete.de/api/v3a/prices" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "release": {
      "ean": "045496430122"
    },
    "price": {
      "condition": "loose",
      "currency": "EUR",
      "amount": 55.00
    }
  }'
```

Bulk create is also supported by sending an array:

```bash
curl -X POST "https://levelcomplete.de/api/v3a/prices" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '[
    {
      "release": {
        "ean": "045496430122"
      },
      "price": {
        "condition": "loose",
        "currency": "EUR",
        "amount": 55.00
      }
    },
    {
      "release": {
        "ean": "045496430122"
      },
      "price": {
        "condition": "cib",
        "currency": "EUR",
        "amount": 89.99
      }
    }
  ]'
```

### Get latest prices by release id

`GET /prices/{releaseId}`

Example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices/1234" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

Optional filters:

- `condition`
- `region`
- `variant`
- `currency`
- `source`

Filtered example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices/1234?condition=cib&region=eu" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

### Get latest prices by EAN

`GET /prices?ean=...`

Example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices?ean=045496430122" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

### Get latest prices by another identifier

`GET /prices?identifierType=...&identifierValue=...`

Example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices?identifierType=igdb&identifierValue=1009" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

PriceCharting product id example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices?identifierType=pricekit&identifierValue=1964" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

### Get price history

**Not supported.** `PriceGuide` keeps one price per condition rather than a
timeline, so `GET /prices/{releaseId}/history` answers 404 and
`getPriceHistory(...)` returns nil.

### Request shape

Release fields:

- `releaseId`: optional internal id
- `ean`: optional shortcut for adding an EAN identifier
- `priceChartingId`: the PriceCharting product id (`PriceGuide.id`). Sent as `identifierType=pricekit`, which is the spelling PriceKit and the app use; the server also accepts `pricecharting`
- `name`: optional when the release already exists
- `platform`: optional
- `region`: optional
- `variant`: optional
- `source`: optional
- `sourceID`: optional
- `identifiers`: optional array of `{ type, value, sourceName, isPrimary }`

Price fields:

- `condition`: required, for example `loose`, `cib`, `new`
- `currency`: required, for example `EUR`, `USD`
- `amount`: required numeric value
- `observedAt`: optional ISO timestamp, defaults to current server time
- `region`: optional price-specific region override
- `variant`: optional price-specific variant override
- `source`: optional
- `sourceItemId`: optional
- `sourceUrl`: optional
