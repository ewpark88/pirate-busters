# 컷신 말풍선을 글자 없이 다시 굽는다 (ADR-063, docs/ASSETS.md).
# 패키지 ui/story/bubble_{left,right}.svg(480x130)에는 자리 표시 글자(<text>)가
# 들어 있어 그대로 쓰면 에셋에 글자가 남는다(절대 규칙 10). <text> 를 지우고 @2x 로
# 그려 png/ui/story/bubble_<side>@2x.png 에 덮어쓴다. 그 뒤 import_assets --merge.
# 사용법: python tool/assets/export_bubbles.py <패키지 경로>   (pip install resvg-py)
import os
import re
import sys

import resvg_py

TEXT = re.compile(r'<text\b[^>]*>.*?</text>', re.S)


def main(pkg):
    for side in ('left', 'right'):
        with open(os.path.join(pkg, 'ui', 'story', f'bubble_{side}.svg'),
                  encoding='utf-8') as f:
            text = TEXT.sub('', f.read())
        png = resvg_py.svg_to_bytes(svg_string=text, width=960, height=260)
        dst = os.path.join(pkg, 'png', 'ui', 'story')
        os.makedirs(dst, exist_ok=True)
        with open(os.path.join(dst, f'bubble_{side}@2x.png'), 'wb') as f:
            f.write(bytes(png))
    print('말풍선 2장')


if __name__ == '__main__':
    main(sys.argv[1])
