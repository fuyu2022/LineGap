"""Generate the bundled Web font from Noto Sans SC (SIL OFL 1.1)."""
from pathlib import Path
from urllib.request import urlretrieve
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parents[1]
cache = root / "builds" / "font-source"
cache.mkdir(parents=True, exist_ok=True)
source = cache / "NotoSansSC.ttf"
base = "https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/"
if not source.exists():
    urlretrieve(base + "NotoSansSC%5Bwght%5D.ttf", source)
destination = root / "assets" / "fonts"
destination.mkdir(parents=True, exist_ok=True)
if not (destination / "OFL.txt").exists():
    urlretrieve(base + "OFL.txt", destination / "OFL.txt")
font = instantiateVariableFont(TTFont(source), {"wght": 400}, inplace=True)
characters = set((root / "scripts" / "game.gd").read_text(encoding="utf-8"))
characters.update(chr(n) for n in range(32, 127))
options = subset.Options()
options.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]
options.name_legacy = True
options.name_languages = [0x409]
subsetter = subset.Subsetter(options=options)
subsetter.populate(text="".join(characters))
subsetter.subset(font)
for name in font["name"].names:
    if name.nameID in [1, 3, 4, 6]:
        value = "LineGapSans-Regular" if name.nameID == 6 else "LineGap Sans"
        name.string = value.encode(name.getEncoding())
font.save(destination / "LineGapSans-Regular.ttf")
print("Generated", destination / "LineGapSans-Regular.ttf")
