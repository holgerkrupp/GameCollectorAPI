# Price API Proposal

This proposal extends the existing `v3a` API with support for video game release prices that:

- are attached to a specific release / product identity
- can vary by condition
- can vary by region
- can vary by variant / edition
- keep a full time history instead of overwriting older values

The design is intentionally aligned with the current backend structure in `webcode/v3a`, where:

- routing is endpoint-based in [webcode/v3a/index.php](/Users/holgerkrupp/Developer/GameCollectorAPI/webcode/v3a/index.php)
- domain logic lives in `*Controller.php` and `*Gateway.php`
- release identification already happens through `EANkeys`, `Retroplace`, `PriceGuide`, and IGDB enrichment in [webcode/v3a/src/EANGateway.php](/Users/holgerkrupp/Developer/GameCollectorAPI/webcode/v3a/src/EANGateway.php)

## Goals

1. Store prices for a concrete release, not only for a game title.
2. Support multiple dimensions at once:
   - `condition`: `loose`, `cib`, `new`, etc.
   - `region`: EU, US, JP, ...
   - `variant`: standard, platinum, collector's edition, bundle, ...
3. Preserve historical price changes.
4. Allow "latest known price" reads without losing the timeline.
5. Leave room for multiple price sources later.

## Recommendation

Use an internal release id as the canonical identity, and treat EAN as an optional external identifier.

Then use an append-only `release_prices` table for historical entries and treat every change as a new row.

Do not update an old price row in place unless you are only correcting metadata immediately after insert. For normal operation, a changed price should create a new record with a new timestamp.

This matches your requirement that prices "could change over time" and makes analytics much easier later.

## Data Model

### 1. Release identity

Your current API already identifies releases from several sources:

- `EANkeys.EAN`
- `EANkeys.sourceID` / `source`
- `Retroplace.RP_sourceID`
- `PriceGuide.upc`

After checking the actual MySQL schema, there are two important constraints in the current data:

- `EANkeys.EAN` is `NOT NULL` and globally `UNIQUE`
- `EANkeys.sourceID` is not unique and appears to identify the game in IGDB, not a concrete release

That means `EANkeys` is useful as a lookup table, but it is not a good canonical release table for prices.

For the price system, I recommend introducing a single internal release key:

`game_releases`

Suggested columns:

```sql
CREATE TABLE game_releases (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(32) NULL,
    source_id VARCHAR(64) NULL,
    igdb_id BIGINT NULL,
    name VARCHAR(255) NOT NULL,
    platform VARCHAR(128) NULL,
    region_code VARCHAR(16) NULL,
    variant_name VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

Notes:

- Do not put a uniqueness rule directly on `source + source_id` unless that source is truly release-level. In the current data, IGDB ids are reused across many EAN rows.
- `variant_name` is part of release identity when the product itself is distinct.
- If you want to avoid a new release table for v1, you can store prices directly against existing identifiers, but a dedicated release table will age much better.

### 1a. Optional external identifiers

Instead of storing `ean` directly on `game_releases`, I recommend a child table:

`release_identifiers`

```sql
CREATE TABLE release_identifiers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    release_id BIGINT UNSIGNED NOT NULL,
    identifier_type VARCHAR(32) NOT NULL,
    identifier_value VARCHAR(128) NOT NULL,
    source_name VARCHAR(64) NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (release_id) REFERENCES game_releases(id),
    UNIQUE KEY uniq_identifier (identifier_type, identifier_value),
    INDEX idx_release_identifiers (release_id, identifier_type)
);
```

Examples:

- `identifier_type = 'ean'`, `identifier_value = '045496430122'`
- `identifier_type = 'upc'`, `identifier_value = '014633372657'`
- `identifier_type = 'retroplace'`, `identifier_value = '123456'`

This gives you:

- releases without EANs
- releases with exactly one EAN
- releases with multiple external identifiers
- room for future identifiers without changing the release table

### 1b. How `EANkeys` should fit

I would treat `EANkeys` as a source/input table rather than the final release table.

Current schema summary:

```sql
CREATE TABLE EANkeys (
  id int unsigned NOT NULL AUTO_INCREMENT,
  EAN bigint NOT NULL,
  source varchar(255) DEFAULT NULL,
  sourceID varchar(255) DEFAULT NULL,
  name varchar(255) DEFAULT NULL,
  version varchar(255) DEFAULT NULL,
  platform varchar(255) DEFAULT NULL,
  deleted tinyint(1) DEFAULT 0,
  user_UUID varchar(255) DEFAULT NULL,
  count int DEFAULT NULL,
  region int DEFAULT NULL,
  coverURL varchar(255) DEFAULT NULL,
  updated datetime DEFAULT current_timestamp(),
  UNIQUE KEY (EAN)
)
```

Implications:

- EAN is mandatory in `EANkeys`, so it cannot store EAN-less releases
- one EAN can only map to one row
- `sourceID` is not safe as a release key because the same IGDB id appears on many rows

So for the price API:

- keep using `EANkeys` to resolve a release when an EAN is provided
- do not make `EANkeys` the canonical release record
- move canonical release identity into `game_releases`
- optionally sync `EANkeys.EAN` into `release_identifiers`

### 2. Controlled dimensions

Some dimensions should be normalized.

`price_conditions`

```sql
CREATE TABLE price_conditions (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label VARCHAR(64) NOT NULL
);
```

Seed values:

- `loose`
- `cib`
- `new`
- `graded`
- `box_only`
- `manual_only`

Optional:

`regions`

If you already have a stable region mapping elsewhere, reuse it. Otherwise:

```sql
CREATE TABLE regions (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(16) NOT NULL UNIQUE,
    label VARCHAR(64) NOT NULL
);
```

Suggested region codes:

- `eu`
- `us`
- `jp`
- `au`
- `world`

### 3. Historical prices

Core table:

```sql
CREATE TABLE release_prices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    release_id BIGINT UNSIGNED NOT NULL,
    condition_id SMALLINT UNSIGNED NOT NULL,
    region_code VARCHAR(16) NULL,
    variant_name VARCHAR(255) NULL,
    currency_code CHAR(3) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    source_name VARCHAR(64) NULL,
    source_item_id VARCHAR(128) NULL,
    source_url VARCHAR(512) NULL,
    observed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (release_id) REFERENCES game_releases(id),
    FOREIGN KEY (condition_id) REFERENCES price_conditions(id),
    INDEX idx_release_lookup (release_id, condition_id, region_code, variant_name, observed_at),
    INDEX idx_latest_lookup (release_id, observed_at DESC)
);
```

Field meaning:

- `observed_at`: when this price was valid / seen / imported
- `created_at`: when the row was written to your DB
- `updated_at`: last metadata correction timestamp

The important business timestamp is `observed_at`.

If you want to represent "current active latest values" more explicitly, keep `is_active` and deactivate older rows in the same logical bucket. But this is optional because the latest row can also be selected by `MAX(observed_at)`.

## Logical uniqueness

The logical price bucket is:

- `release_id`
- `condition`
- `region_code`
- `variant_name`
- `currency_code`
- optionally `source_name`

That means:

- one release can have many prices
- one release can have one `loose` EU price and one `cib` EU price
- one release can have separate `standard` and `collector` prices
- one release can have multiple sources if you want that later

## API shape

Add a new endpoint:

- `prices`

Update [webcode/v3a/index.php](/Users/holgerkrupp/Developer/GameCollectorAPI/webcode/v3a/index.php) to register it beside `playtimes` and `ean`.

Recommended routes:

- `GET /api/v3a/prices/{releaseId}`
- `GET /api/v3a/prices?ean=...`
- `GET /api/v3a/prices?identifierType=retroplace&identifierValue=123456`
- `POST /api/v3a/prices`
- `GET /api/v3a/prices/{releaseId}/history`

### POST behavior

`POST /prices` should append a new historical price row.

Request example:

```json
{
  "release": {
    "name": "The Legend of Zelda: Twilight Princess",
    "platform": "Nintendo GameCube",
    "region": "eu",
    "variant": "Player's Choice",
    "identifiers": [
      {
        "type": "ean",
        "value": "045496430122",
        "isPrimary": true
      }
    ]
  },
  "price": {
    "condition": "cib",
    "currency": "EUR",
    "amount": 89.99,
    "observedAt": "2026-06-30T10:45:00Z",
    "source": "manual",
    "sourceUrl": null
  }
}
```

Bulk insert should also be supported, because your current API already accepts arrays for `playtimes` and `ean`.

### GET latest behavior

`GET /prices/{releaseId}` should return the latest price per bucket.

Example response:

```json
{
  "releaseId": 1234,
  "prices": [
    {
      "condition": "loose",
      "region": "eu",
      "variant": "standard",
      "currency": "EUR",
      "amount": 55.00,
      "observedAt": "2026-06-30T10:45:00Z"
    },
    {
      "condition": "cib",
      "region": "eu",
      "variant": "standard",
      "currency": "EUR",
      "amount": 89.99,
      "observedAt": "2026-06-30T10:45:00Z"
    }
  ]
}
```

### GET history behavior

`GET /prices/{releaseId}/history?condition=cib&region=eu&variant=standard`

Example response:

```json
{
  "releaseId": 1234,
  "history": [
    {
      "condition": "cib",
      "region": "eu",
      "variant": "standard",
      "currency": "EUR",
      "amount": 74.99,
      "observedAt": "2026-04-01T08:00:00Z"
    },
    {
      "condition": "cib",
      "region": "eu",
      "variant": "standard",
      "currency": "EUR",
      "amount": 89.99,
      "observedAt": "2026-06-30T10:45:00Z"
    }
  ]
}
```

## Query strategy

For "latest per bucket", use a grouped latest query similar to what you already do in [webcode/v3a/src/PlayTimesGateway.php](/Users/holgerkrupp/Developer/GameCollectorAPI/webcode/v3a/src/PlayTimesGateway.php), but grouped by the price dimensions instead of `type`.

Conceptually:

```sql
SELECT rp.*
FROM release_prices rp
JOIN (
    SELECT
        release_id,
        condition_id,
        COALESCE(region_code, '') AS region_code,
        COALESCE(variant_name, '') AS variant_name,
        currency_code,
        MAX(observed_at) AS max_observed_at
    FROM release_prices
    WHERE release_id = :release_id
    GROUP BY
        release_id,
        condition_id,
        COALESCE(region_code, ''),
        COALESCE(variant_name, ''),
        currency_code
) latest
ON rp.release_id = latest.release_id
AND rp.condition_id = latest.condition_id
AND COALESCE(rp.region_code, '') = latest.region_code
AND COALESCE(rp.variant_name, '') = latest.variant_name
AND rp.currency_code = latest.currency_code
AND rp.observed_at = latest.max_observed_at;
```

## Controller / Gateway structure

Add:

- `webcode/v3a/src/PricesController.php`
- `webcode/v3a/src/PricesGateway.php`

Suggested responsibilities:

`PricesController`

- validate payloads
- route `GET`, `POST`
- parse filters like `condition`, `region`, `variant`, `history`

`PricesGateway`

- resolve or create `game_releases`
- insert new `release_prices` rows
- fetch latest prices
- fetch history

## Validation rules

Recommended validation:

- `amount` required and `>= 0`
- `currency` required, ISO-4217 uppercase
- `condition` required
- `observedAt` optional, defaults to now
- at least one release identifier required:
  - `releaseId`, or
  - `release.identifiers[]`, or
  - enough descriptive release fields to create a release intentionally

For convenience you can still accept top-level `ean` on the API and translate it internally into:

```json
{
  "type": "ean",
  "value": "..."
}
```

If `variant` is omitted, treat it as `standard` at the API layer or `NULL` at the DB layer. I would prefer `NULL` in storage and normalize to `"standard"` in responses if you want a friendlier client contract.

## Versioning advice

I would keep this in `v3a` first instead of creating `v4` immediately, because:

- the API is still relatively compact
- `prices` is additive
- existing clients will not break

If you later refactor all endpoints toward a more consistent release-centric model, that would be a good moment for `v4`.

## Swift client additions

In the Swift package, I would add:

- `GCPricePoint`
- `GCReleasePrices`
- `GCAPIconnector.getPrices(...)`
- `GCAPIconnector.push(price:)`

Suggested models:

```swift
public struct GCPricePoint: Codable, Sendable {
    public var condition: String
    public var region: String?
    public var variant: String?
    public var currency: String
    public var amount: Double
    public var observedAt: String
}

public struct GCReleasePrices: Codable, Sendable {
    public var releaseId: Int
    public var prices: [GCPricePoint]
}
```

## Migration options

### Option A: Clean new tables

Best long-term option.

- create `game_releases`
- create `release_identifiers`
- create `price_conditions`
- create `release_prices`
- optionally import old `PriceGuide` data into them

Pros:

- clean history model
- explicit dimensions
- easier future analytics

Cons:

- more upfront migration work

### Option B: Evolve existing `PriceGuide`

If `PriceGuide` already contains useful source data, you could alter it:

- add `condition`
- add `region_code`
- add `variant_name`
- add `currency_code`
- add `observed_at`
- add `created_at`
- add `updated_at`

Pros:

- faster first step

Cons:

- likely carries forward naming and identity limitations
- may be harder to distinguish imported raw guide data from curated app price entries

My recommendation is Option A.

## Practical rollout

1. Add the new tables.
2. Add `PricesController` and `PricesGateway`.
3. Register `prices` in `index.php`.
4. Implement:
   - `POST /prices`
   - `GET /prices/{releaseId}`
   - `GET /prices/{releaseId}/history`
5. Add Swift client models and methods.
6. Optionally add an import job from `PriceGuide`.

## One important modeling decision

You need to decide whether `variant` is:

- part of the release identity, or
- just a price dimension

My recommendation:

- if the variant has its own barcode / source identity, make it part of `game_releases`
- if it is just a market distinction without unique product identity, allow it only on the price row

In practice, supporting both is fine:

- `game_releases.variant_name` for hard identity
- `release_prices.variant_name` for softer market labeling

## Final recommendation

If we optimize for correctness and future flexibility, I would implement:

- a new `prices` endpoint
- a dedicated `game_releases` table
- a `release_identifiers` table where EAN is one optional identifier type
- an append-only `release_prices` history table
- `observed_at` as the business timestamp for price changes
- latest-price queries derived from history instead of destructive updates

This gives you clean support for:

- loose / CIB / sealed
- EU / US / JP
- standard / platinum / collector's edition
- releases with or without EAN
- price changes over time

without painting the API into a corner.
