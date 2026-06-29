import csv
import os
import requests
import time

# ======== CONFIGURATION ========
API_KEY = "3e334743b3f0c005acca72c8f00e59e72246e9bc22fe6115b41d844cb481d3fb"  # <-- Replace with your actual RetroPlace API key
START_ID = 217262                     # Starting ID (only used if CSV is empty)
NUM_ITEMS = 10                 # Number of new IDs to fetch
OUTPUT_CSV = "retroplace_items.csv"
DELAY_SECONDS = 0.1              # Delay between requests
# ================================

BASE_URL = f"https://www.retroplace.com/en/api/{API_KEY}/getItemById"


def fetch_item(item_id: int):
    """Fetch a single item by ID from RetroPlace API."""
    url = f"{BASE_URL}?rp_id={item_id}"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data.get("result") == "success":
            return {
                "rp_id": data.get("rp_id"),
                "title": data.get("title", ""),
                "system": data.get("system", ""),
                "region": ",".join(data.get("region", [])),
                "barcode": data.get("barcode", ""),
                "packshot_url": data.get("packshot_url", "")
            }
        return None
    except Exception as e:
        print(f"⚠️ Error fetching ID {item_id}: {e}")
        return None


def get_last_id_from_csv(filename: str) -> int:
    """Return the last rp_id from the CSV file if it exists, else 0."""
    if not os.path.exists(filename):
        return 0
    try:
        with open(filename, "r", encoding="utf-8") as f:
            lines = f.readlines()
            if len(lines) <= 1:  # only header
                return 0
            last_line = lines[-1].strip().split(",")
            if last_line and last_line[0].isdigit():
                return int(last_line[0])
    except Exception as e:
        print(f"⚠️ Could not read last ID from CSV: {e}")
    return 0


def ensure_csv_header(filename: str):
    """Ensure the CSV file has a header."""
    if not os.path.exists(filename):
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f, fieldnames=["rp_id", "title", "system", "region", "barcode", "packshot_url"]
            )
            writer.writeheader()


def append_to_csv(filename: str, item: dict):
    """Append one row to the CSV file."""
    with open(filename, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f, fieldnames=["rp_id", "title", "system", "region", "barcode", "packshot_url"]
        )
        writer.writerow(item)


def main():
    ensure_csv_header(OUTPUT_CSV)
    last_id = get_last_id_from_csv(OUTPUT_CSV)

    start_id = last_id + 1 if last_id > 0 else START_ID
    end_id = start_id + NUM_ITEMS - 1

    print(f"Starting from ID {start_id} (last saved ID: {last_id})")
    print(f"Will fetch {NUM_ITEMS} items (ending at {end_id})\n")

    fetched = 0
    for item_id in range(start_id, end_id + 1):
        item_data = fetch_item(item_id)
        if item_data:
            append_to_csv(OUTPUT_CSV, item_data)
            print(f"✅ [{item_id}] {item_data['title']}")
            fetched += 1
        else:
            print(f"❌ No item found for ID {item_id}")
        time.sleep(DELAY_SECONDS)

    print(f"\n✅ Done! Checked {NUM_ITEMS} IDs ({start_id}–{end_id}).")
    print(f"📦 Found {fetched} valid items.")
    print(f"💾 Progress saved to: {OUTPUT_CSV}")


if __name__ == "__main__":
    main()