Client side to talk to the Server hosting some of Game Collectors data.

## Prices API

The API now supports release-based price history with:

- optional EAN-based release identification
- optional PriceCharting-style identifier support via the legacy `items.id`
- additional identifiers such as source ids
- multiple price dimensions like condition, region, and variant
- historical price tracking via `observed_at`

When a release has no current entry in `release_prices`, the server can silently bootstrap it from legacy tables (`EANkeys`, `items`, `PriceGuide`) and return old `PriceGuide` values as a temporary seed response. Those fallback rows are marked with:

- `source_name = "PriceGuideLegacy"`
- `is_legacy_seed = true`
- `observed_at = null`

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

PriceCharting-style example using the legacy `items.id`:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices?identifierType=pricecharting&identifierValue=5" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

### Get price history

`GET /prices/{releaseId}/history`

Example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices/1234/history" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

Filtered history example:

```bash
curl -X GET "https://levelcomplete.de/api/v3a/prices/1234/history?condition=cib&region=eu&variant=Player%27s%20Choice" \
  -H "APIkey: YOUR_API_KEY" \
  -H "Accept: application/json"
```

### Request shape

Release fields:

- `releaseId`: optional internal id
- `ean`: optional shortcut for adding an EAN identifier
- `priceChartingId`: optional shortcut for adding a legacy `items.id` / PriceCharting-style identifier
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
