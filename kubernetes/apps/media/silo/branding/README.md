# Mikeflix brand assets for Silo

The mark is a red ribbon folded into an M. The wordmark is set in Anton (SIL Open Font License), converted to paths, so no font is needed.

Colors:

- Mikeflix red (accent color): `#E4202B`
- Red light: `#FF4D56`
- Red dark: `#9A0F18`
- Cinema Dark background: `#0B0B0F`
- Text light: `#F7F7FA`

## Files

- `logo/mikeflix-wordmark.svg`, `logo/mikeflix-wordmark-2000.png`: red wordmark on a transparent background. Use it on dark and light surfaces.
- `logo/mikeflix-wordmark-white.svg`, `logo/mikeflix-wordmark-black.svg`: one-color wordmarks.
- `logo/mikeflix-lockup.svg`, `logo/mikeflix-lockup-2000.png`: mark and wordmark side by side.
- `icon/mikeflix-icon.svg`, `icon/mikeflix-icon-{1024,512,256,128}.png`: the mark on a dark rounded tile.
- `icon/mikeflix-mark.svg`, `icon/mikeflix-mark-1024.png`: the mark alone on a transparent background.
- `icon/mikeflix-icon-flat.svg`: a one-color mark on the tile, for very small sizes.
- `favicon/favicon.ico`: 16, 32 and 48 pixel sizes in one file.
- `favicon/favicon.svg`, `favicon/favicon-{16,32,48,64}.png`: single sizes.
- `favicon/apple-touch-icon-180.png`, `favicon/android-chrome-{192,512}.png`, `favicon/maskable-512.png`: home screen icons.
- `background/login-background-{1920x1080,2560x1440,3840x2160}.{jpg,webp,png}`: the login background. Dark gradient, two soft light beams, a faint M on the right, a vignette. The center stays clear for the sign-in card.
- `background/login-background.svg`: the editable source for the background.

## Upload the assets to Silo

1. Open Silo as an admin user.
2. Go to Admin > Server > General.
3. Under Identity, set Server name to `Mikeflix`.
4. Set Login subtitle if you want a line under the name.
5. Save.
6. Go to Admin > Server > Appearance.
7. Under Logos and icons, upload `logo/mikeflix-wordmark-2000.png` as Logo (wordmark).
8. Upload `icon/mikeflix-icon-512.png` as Logo (icon).
9. Upload `favicon/favicon.ico` as Favicon. If Silo rejects the file, upload `favicon/favicon-64.png`.
10. Upload `background/login-background-2560x1440.jpg` as Login background.
11. Under Colors, set Accent color to `#E4202B`.
12. Save.
13. Open a normal page and the signed-out sign-in page to look at the result.

Silo caches the favicon and the app manifest for five minutes after a change.

## Rebuild the assets

The build script is `build.js` in this folder. It needs Node, `opentype.js`, `@resvg/resvg-js`, the Anton font file and ImageMagick.

1. Run `node tools/build.js <output folder> anton`.
2. Run `convert favicon-16.png favicon-32.png favicon-48.png favicon.ico` in the favicon folder.

## Why this folder is in the repository

Flux only reads `../app`, so nothing here reaches the cluster. The files live here so they are easy to download and to rebuild. Silo stores the uploaded copies in its artwork storage on the `silo-config` volume.
