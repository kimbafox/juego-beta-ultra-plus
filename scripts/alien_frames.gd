extends RefCounted
## Regiones, anclajes y límites visibles de las cuatro hojas originales.
const WALK_RECTS = [
 [Rect2(0,0,540,740), Rect2(540,0,484,740), Rect2(0,740,510,796), Rect2(510,740,514,796)],
 [Rect2(0,0,540,755), Rect2(540,0,484,755), Rect2(0,755,510,781), Rect2(510,755,514,781)]
]
const SHOT_RECTS = [
 [Rect2(0,0,550,750), Rect2(550,0,474,750), Rect2(0,750,480,786), Rect2(480,750,544,786)],
 [Rect2(0,0,537,755), Rect2(537,0,487,755), Rect2(0,755,480,781), Rect2(480,755,544,781)]
]
const WALK_ANCHORS = [[300,800,250,750], [280,780,300,800]]
const SHOT_ANCHORS = [[265,735,285,800], [220,715,300,805]]
const MUZZLES = [[Vector2(538,160),Vector2(939,156),Vector2(26,926),Vector2(559,929)], [Vector2(535,145),Vector2(939,145),Vector2(24,899),Vector2(580,902)]]
# Límites visibles: se ignoran píxeles casi transparentes al alinear los pies.
const VISIBLE_BOUNDS = [[[Rect2i(84,12,434,711), Rect2i(29,11,417,715), Rect2i(48,9,429,712), Rect2i(27,1,419,719)],
 [Rect2i(91,18,448,694), Rect2i(6,20,455,692), Rect2i(25,35,455,684), Rect2i(0,38,509,680)]],
[[Rect2i(57,33,474,671), Rect2i(19,31,456,689), Rect2i(39,29,451,699), Rect2i(7,31,473,691)],
 [Rect2i(46,57,489,644), Rect2i(4,57,482,643), Rect2i(22,59,458,646), Rect2i(0,53,516,651)]]]
