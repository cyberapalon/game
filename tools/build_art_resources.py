#!/usr/bin/env python3
"""Build Godot atlas resources from retained PNGs; never generate replacement art.

ImageMagick reads alpha bounds and packs cropped terrain cells. Character/VFX
pixels stay in their original sheets and are selected through AtlasTexture.
Run from the repository root: python3 tools/build_art_resources.py
"""

from pathlib import Path
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def dimensions(path: Path) -> tuple[int, int]:
    return struct.unpack(">II", path.read_bytes()[16:24])


def bounds(path: Path, box: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    x, y, width, height = box
    result = subprocess.check_output([
        "magick", str(path), "-crop", f"{width}x{height}+{x}+{y}", "+repage",
        "-alpha", "extract", "-threshold", "15%", "-format", "%@", "info:",
    ], text=True)
    match = re.fullmatch(r"(\d+)x(\d+)\+(\d+)\+(\d+)", result.strip())
    if not match:
        raise ValueError(f"Cannot read alpha bounds for {path}: {result}")
    bw, bh, bx, by = map(int, match.groups())
    # A small safety border retains antialiasing around the cutout.
    left, top = max(0, bx - 4), max(0, by - 4)
    right, bottom = min(width, bx + bw + 4), min(height, by + bh + 4)
    return left, top, right - left, bottom - top


def frame_sheet(relative: str, rows: list[tuple[str, int, bool]], normalized: bool) -> None:
    path = ROOT / relative
    width, height = dimensions(path)
    parts = [
        f'[gd_resource type="SpriteFrames" load_steps={len(rows) * 4 + 2} format=3]',
        f'[ext_resource type="Texture2D" path="res://{relative}" id="1"]',
    ]
    animations = []
    for row, (name, speed, loop) in enumerate(rows):
        ids = []
        for column in range(4):
            left, right = width * column // 4, width * (column + 1) // 4
            top, bottom = height * row // len(rows), height * (row + 1) // len(rows)
            cw, ch = right - left, bottom - top
            bx, by, bw, bh = 0, 0, cw, ch
            if normalized:
                bx, by, bw, bh = bounds(path, (left, top, cw, ch))
            key = f"{name}{column}"
            block = (
                f'[sub_resource type="AtlasTexture" id="{key}"]\n'
                'atlas = ExtResource("1")\n'
                f'region = Rect2({left + bx}, {top + by}, {bw}, {bh})\n'
                'filter_clip = true\n'
            )
            if normalized:
                baseline = int(ch * 0.94)
                block += f'margin = Rect2({bx}, {baseline - bh}, {cw - bw}, {ch - bh})\n'
            parts.append(block)
            ids.append(f'{{"duration": 1.0, "texture": SubResource("{key}")}}')
        animations.append(
            '{"frames": [' + ', '.join(ids) + '], '
            f'"loop": {str(loop).lower()}, "name": &"{name}", "speed": {float(speed)}}}'
        )
    parts.append('[resource]\nanimations = [' + ',\n'.join(animations) + ']\n')
    output = path.with_name(path.stem.replace('_sheet', '_frames') + '.tres')
    output.write_text('\n\n'.join(parts))
    print(output.relative_to(ROOT))


def environment() -> None:
    source = ROOT / 'assets/environment/conservatory_source.png'
    width, height = dimensions(source)
    # Remove presentation gutters and normalize only the eight terrain cells.
    temporary = ROOT / 'build/art_pipeline'
    temporary.mkdir(parents=True, exist_ok=True)
    cells = []
    for row in range(2):
        for column in range(4):
            left, right = width * column // 4 + 6, width * (column + 1) // 4 - 6
            top, bottom = height * row // 4 + 6, height * (row + 1) // 4 - 6
            if row == 0:
                top = 33  # Align the flat moss surface, omitting tall flower tips.
            cell = temporary / f'tile_{row}_{column}.png'
            subprocess.run([
                'magick', str(source), '-crop', f'{right-left}x{bottom-top}+{left}+{top}',
                '+repage', '-resize', '256x256!', str(cell),
            ], check=True)
            cells.append(str(cell))
    atlas = ROOT / 'assets/environment/conservatory_tiles.png'
    row_images = [temporary / 'row_0.png', temporary / 'row_1.png']
    for row, output in enumerate(row_images):
        subprocess.run(['magick', *cells[row*4:(row+1)*4], '+append', str(output)], check=True)
    subprocess.run(['magick', *map(str, row_images), '-append', str(atlas)], check=True)
    tile_blocks = '\n'.join(f'{column}:{row}/0 = 0' for row in range(2) for column in range(4))
    (ROOT / 'assets/environment/conservatory_tileset.tres').write_text(
        '[gd_resource type="TileSet" load_steps=3 format=3]\n\n'
        '[ext_resource type="Texture2D" path="res://assets/environment/conservatory_tiles.png" id="1"]\n\n'
        '[sub_resource type="TileSetAtlasSource" id="Atlas"]\n'
        'texture = ExtResource("1")\ntexture_region_size = Vector2i(256, 256)\n'
        + tile_blocks + '\n\n[resource]\ntile_size = Vector2i(256, 256)\nsources/0 = SubResource("Atlas")\n'
    )
    for row in range(2, 4):
        for column in range(4):
            left, right = width * column // 4 + 4, width * (column + 1) // 4 - 4
            top, bottom = height * row // 4 + 4, height * (row + 1) // 4 - 4
            cw, ch = right-left, bottom-top
            bx, by, bw, bh = bounds(source, (left, top, cw, ch))
            (ROOT / f'assets/environment/prop_{column}_{row}.tres').write_text(
                '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                '[ext_resource type="Texture2D" path="res://assets/environment/conservatory_source.png" id="1"]\n\n'
                '[resource]\natlas = ExtResource("1")\n'
                f'region = Rect2({left+bx}, {top+by}, {bw}, {bh})\n'
                f'margin = Rect2({bx}, {ch-bh}, {cw-bw}, {ch-bh})\nfilter_clip = true\n'
            )
    print('assets/environment/conservatory_tileset.tres and eight prop resources')


if __name__ == '__main__':
    frame_sheet('assets/characters/keeper_sheet.png', [
        ('idle', 4, True), ('run', 12, True), ('jump', 8, False),
        ('fall', 8, False), ('attack', 18, False), ('dash', 22, False),
    ], True)
    frame_sheet('assets/characters/moss_walker_sheet.png', [
        ('idle', 4, True), ('move', 9, True), ('hit', 16, False), ('death', 10, False),
    ], True)
    frame_sheet('assets/vfx/garden_sheet.png', [
        ('slash', 20, False), ('dust', 15, False), ('impact', 20, False), ('dash', 20, False),
    ], False)
    environment()
