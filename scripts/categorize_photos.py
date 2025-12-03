#!/usr/bin/env python3
"""
Automatically categorize photos using Amazon Nova 2 Lite.

Scans the images/ directory, sends each photo to Nova for categorization,
and updates data/photos.json with the results.

Usage:
    python scripts/categorize_photos.py
    python scripts/categorize_photos.py --dry-run  # Preview without updating
"""

import os
import json
import base64
import argparse
from pathlib import Path
from typing import Dict, List

from langchain_amazon_nova import ChatAmazonNova
from langchain_core.messages import HumanMessage


def encode_image_to_base64(image_path: str) -> str:
    """Encode a local image file to base64 data URL."""
    # Determine MIME type from extension
    ext = Path(image_path).suffix.lower()
    mime_types = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp'
    }
    mime_type = mime_types.get(ext, 'image/jpeg')

    # Read and encode image
    with open(image_path, 'rb') as f:
        image_data = base64.b64encode(f.read()).decode('utf-8')

    return f"data:{mime_type};base64,{image_data}"


def categorize_image(model: ChatAmazonNova, image_path: str) -> Dict[str, str]:
    """
    Send image to Nova and get categorization.

    Returns dict with 'category', 'title', and 'description'.
    """
    print(f"Categorizing: {image_path}")

    # Encode image
    image_data_url = encode_image_to_base64(image_path)

    # Create prompt
    prompt = """Analyze this photograph and provide:
1. Category: Choose ONE from [landscape, portrait, street, nature]
2. Title: A short, descriptive title (3-6 words)
3. Description: A brief description (1-2 sentences)

Format your response as JSON:
{
  "category": "landscape|portrait|street|nature",
  "title": "Photo Title Here",
  "description": "Brief description here."
}"""

    # Create message with image
    message = HumanMessage(content=[
        {"type": "text", "text": prompt},
        {"type": "image_url", "image_url": {"url": image_data_url}}
    ])

    # Get response
    response = model.invoke([message])

    # Parse JSON response
    try:
        # Extract JSON from response (handle markdown code blocks if present)
        content = response.content.strip()
        if content.startswith('```'):
            # Remove markdown code block formatting
            content = content.split('\n', 1)[1].rsplit('\n', 1)[0]
            if content.startswith('json'):
                content = content[4:].strip()

        result = json.loads(content)
        return result
    except json.JSONDecodeError as e:
        print(f"Warning: Failed to parse JSON response: {e}")
        print(f"Response was: {response.content}")
        # Return a default categorization
        return {
            "category": "landscape",
            "title": Path(image_path).stem.replace('-', ' ').replace('_', ' ').title(),
            "description": "Photo description unavailable."
        }


def scan_images(images_dir: str) -> List[str]:
    """Get list of image files in directory."""
    supported_exts = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    images = []

    for file in Path(images_dir).iterdir():
        if file.is_file() and file.suffix.lower() in supported_exts:
            images.append(str(file))

    return sorted(images)


def load_existing_photos(photos_json: str) -> Dict[str, Dict]:
    """Load existing photos.json and index by filename."""
    try:
        with open(photos_json, 'r') as f:
            photos = json.load(f)
        return {photo['file']: photo for photo in photos}
    except FileNotFoundError:
        return {}


def main():
    parser = argparse.ArgumentParser(description='Categorize photos using Amazon Nova')
    parser.add_argument('--dry-run', action='store_true', help='Preview without updating files')
    parser.add_argument('--model', default='nova-2-lite-v1', help='Nova model to use')
    parser.add_argument('--images-dir', default='images', help='Images directory')
    parser.add_argument('--photos-json', default='data/photos.json', help='Photos JSON file')
    args = parser.parse_args()

    # Initialize model
    print(f"Initializing {args.model}...")
    model = ChatAmazonNova(model=args.model, temperature=0.7)

    # Scan for images
    print(f"\nScanning {args.images_dir}/ for photos...")
    image_files = scan_images(args.images_dir)
    print(f"Found {len(image_files)} images")

    if not image_files:
        print("No images found. Add photos to images/ directory first.")
        return

    # Load existing photos
    existing_photos = load_existing_photos(args.photos_json)

    # Process each image
    new_photos = []
    for image_path in image_files:
        filename = Path(image_path).name

        # Skip if already catalogued
        if filename in existing_photos:
            print(f"Skipping {filename} (already catalogued)")
            new_photos.append(existing_photos[filename])
            continue

        # Categorize with Nova
        result = categorize_image(model, image_path)

        # Create photo entry
        photo_id = Path(image_path).stem
        photo_entry = {
            "id": photo_id,
            "file": filename,
            "category": result['category'],
            "title": result['title'],
            "description": result['description']
        }

        print(f"  Category: {result['category']}")
        print(f"  Title: {result['title']}")
        print(f"  Description: {result['description']}\n")

        new_photos.append(photo_entry)

    # Update photos.json
    if args.dry_run:
        print("\n[DRY RUN] Would update photos.json with:")
        print(json.dumps(new_photos, indent=2))
    else:
        with open(args.photos_json, 'w') as f:
            json.dump(new_photos, f, indent=2)
        print(f"\n✓ Updated {args.photos_json} with {len(new_photos)} photos")


if __name__ == '__main__':
    main()
