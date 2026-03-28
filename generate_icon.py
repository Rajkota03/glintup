from PIL import Image, ImageDraw, ImageFont
import math
import os

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background - dark charcoal
bg_color = (26, 26, 26, 255)  # #1A1A1A
draw.rectangle([0, 0, SIZE, SIZE], fill=bg_color)

# Gold color
gold = (200, 169, 81, 255)  # #C8A951
gold_light = (212, 189, 121, 255)  # lighter gold for sparkle

# Find a good serif font on macOS
font_paths = [
    '/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf',
    '/System/Library/Fonts/Supplemental/Georgia Bold.ttf',
    '/Library/Fonts/Playfair Display Bold.ttf',
    '/System/Library/Fonts/NewYork.ttf',
    '/System/Library/Fonts/Supplemental/Palatino Bold.ttf',
]

font = None
for fp in font_paths:
    if os.path.exists(fp):
        try:
            font = ImageFont.truetype(fp, 620)
            print(f"Using font: {fp}")
            break
        except:
            continue

if font is None:
    print("No suitable font found, using default")
    font = ImageFont.load_default()

# Center the G
text = "G"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (SIZE - text_width) // 2 - bbox[0]
y = (SIZE - text_height) // 2 - bbox[1] + 20  # slight offset down

draw.text((x, y), text, fill=gold, font=font)

# Draw sparkle (4-pointed star) near top-right of G
def draw_sparkle(draw, cx, cy, size, color):
    """Draw a 4-pointed sparkle star"""
    points_v = [(cx, cy - size), (cx - size*0.15, cy), (cx, cy + size), (cx + size*0.15, cy)]
    points_h = [(cx - size, cy), (cx, cy - size*0.15), (cx + size, cy), (cx, cy + size*0.15)]
    draw.polygon(points_v, fill=color)
    draw.polygon(points_h, fill=color)

# Main sparkle - top right area
sparkle_x = SIZE // 2 + 200
sparkle_y = SIZE // 2 - 220
draw_sparkle(draw, sparkle_x, sparkle_y, 45, gold_light)

# Small secondary sparkle
draw_sparkle(draw, sparkle_x + 70, sparkle_y - 50, 18, gold_light)

# Save the icon
output_path = '/Users/rajnikanthkota/glintup/app_icon_1024.png'
img.save(output_path, 'PNG')
print(f"Icon saved to {output_path}")
print(f"Size: {img.size}")
