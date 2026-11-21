# Class of '87: Art Plan

Last updated: 2026-11-02

The goal is to spend no money on art.

## Which tool makes what
| Asset | Tool | Cost |
|---|---|---|
| Rooms and props (3D) | Code in `src/shared/Rooms.luau`, drawn from simple parts | Free |
| Wall signs and chalkboards | Roblox text on surfaces; no image uploads needed | Free |
| Rock, wood and metal surfaces | Roblox's built-in materials | Free |
| Game icon and thumbnails | Satori, in `art/generate.mjs` | Free |
| Later HUD or purchase icons | Satori | Free |

Satori images used inside the game would have to be uploaded to Roblox first, which is why in-game signs use Roblox text.

## What Satori is
[Satori](https://github.com/vercel/satori) is Vercel's open-source library (MPL-2.0) for
turning HTML and CSS layouts into SVG images. A second tool, such as resvg, turns those into PNG files.

**It isn't an AI image generator.** It draws exactly the shapes, gradients, text and images
described in code. It can't invent a picture from a prompt, paint detailed illustrations or
make 3D models. Best results come from bold graphic designs: strong type, silhouettes, light
and simple shapes.

## Current art
- `art/output/thumbnail.png`: school corridor, footprints and red exit glow, with the title
- `art/output/icon.png`: chalkboard "87" and "ABSENT"
- `art/previews/`: offline previews of all 12 room types. Library books were added to both sides of the shelves after these were taken.

To regenerate: `cd art && npm install && npm run build`.

**The previews aren't what players will see.** They use a basic browser renderer with brighter
lighting and without Roblox's shadows, fog, flashlight or effects. To remake them, run
`luau tests/dump_preview.luau > level.json`, then serve `tests/preview/index.html` next to that file.

## Target sizes
These come mostly from third-party guides, so check Creator Hub when uploading.

| Asset | Size | Source |
|---|---|---|
| Game icon | 512×512; should still read at about 150×150 | [Roblox](https://create.roblox.com/docs/production/promotion/game-icons), [Moda](https://moda.app/resources/sizes/roblox) |
| Thumbnail | 1920×1080, 16:9 | [Moda](https://moda.app/resources/sizes/roblox-thumbnail) |

## Visual direction
Cold moonlight, sickly fluorescent light and old institutional colors: checker floors, faded green
paint, red and teal lockers, exposed brick and rust. Red marks danger and the exit. Titles use
Permanent Marker, like chalk, with Special Elite for small typed lines.

**No figures, ever.** Trophies are cups only, "GO EAGLES" is text with no bird, and the chemistry
lab has no skeleton. Threats are shown by footprints, damage and darkness.

Fonts come through Fontsource. Check each license before publishing.
