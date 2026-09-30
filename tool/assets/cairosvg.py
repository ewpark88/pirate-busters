# 이 PC 에는 cairo 가 없어 resvg 로 대신 그린다 (export_png.py 전용 대역).
import resvg_py

def svg2png(bytestring=None, output_width=None, output_height=None, **_):
    svg = bytestring.decode('utf-8') if isinstance(bytestring, (bytes, bytearray)) else bytestring
    out = resvg_py.svg_to_bytes(svg_string=svg, width=int(output_width) if output_width else None,
                                height=int(output_height) if output_height else None)
    return bytes(out)
