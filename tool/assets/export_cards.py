# 등급 카드에 넣을 해적 그림을 굽는다 (ADR-062, docs/ASSETS.md).
# 패키지 ui/cards/cards.json 의 `character`: 원본 <id>_<team>.svg(240x324)를
# 0.74배로 놓는다. 앱은 @2x 만 쓰므로 1.48배로 그려
# png/characters/<id>/<id>_<team>_card@2x.png 에 둔다. 그 뒤 import_assets --merge.
# 사용법: python tool/assets/export_cards.py <패키지 경로>   (pip install resvg-py)
import os
import sys

import resvg_py

CARD = 0.74 * 2


def main(pkg):
    src = os.path.join(pkg, 'characters')
    count = 0
    for cid in sorted(os.listdir(src)):
        for team in ('blue', 'red'):
            svg = os.path.join(src, cid, f'{cid}_{team}.svg')
            if not os.path.exists(svg):
                continue
            with open(svg, encoding='utf-8') as f:
                text = f.read()
            png = resvg_py.svg_to_bytes(svg_string=text, width=round(240 * CARD),
                                        height=round(324 * CARD))
            dst = os.path.join(pkg, 'png', 'characters', cid)
            os.makedirs(dst, exist_ok=True)
            with open(os.path.join(dst, f'{cid}_{team}_card@2x.png'), 'wb') as f:
                f.write(bytes(png))
            count += 1
    print(f'카드 그림 {count}장')


if __name__ == '__main__':
    main(sys.argv[1])
