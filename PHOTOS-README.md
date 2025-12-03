# Photo Gallery Setup

Your photography page now uses a dynamic system that loads photos from `data/photos.json`.

## How to Add Photos

1. **Add image files** to the `images/` directory
2. **Update** `data/photos.json` with photo metadata:

```json
{
  "id": "unique-photo-id",
  "file": "photo-filename.jpg",
  "category": "landscape|portrait|street|nature",
  "title": "Photo Title",
  "description": "Optional description shown in lightbox"
}
```

## Current Categories

- `landscape` - Landscape photography
- `portrait` - Portrait photography
- `street` - Street photography
- `nature` - Nature photography

## Auto-Categorization with Amazon Nova

Use the included script to automatically categorize photos with Amazon Nova 2 Lite.

### Setup

1. **Install dependencies:**
   ```bash
   pip install -r scripts/requirements.txt
   ```

2. **Set your Nova API credentials:**
   ```bash
   export NOVA_API_KEY="your-bearer-token-here"
   export NOVA_BASE_URL="https://nova-api-endpoint"
   ```

### Usage

**Categorize all new photos:**
```bash
python scripts/categorize_photos.py
```

**Preview without updating:**
```bash
python scripts/categorize_photos.py --dry-run
```

**Options:**
- `--dry-run` - Preview categorization without updating photos.json
- `--model nova-2-lite-v1` - Specify Nova model (default: nova-2-lite-v1)
- `--images-dir images` - Images directory (default: images)
- `--photos-json data/photos.json` - Output file (default: data/photos.json)

### How It Works

1. Scans `images/` for new photos (skips already catalogued ones)
2. Sends each image to Amazon Nova 2 Lite with vision prompt
3. Gets back category, title, and description
4. Updates `data/photos.json` automatically

**Workflow:**
1. Drop photos in `images/`
2. Run `python scripts/categorize_photos.py`
3. Photos appear on your site automatically
