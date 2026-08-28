// Repeated offsets compose without nesting on Typst's function-call stack.
#import "@preview/typograph:0.3.0" as typ
#import "../position-helpers.typ": layout, named, xy, pair-close

#context {
  let g = typ.gate(2, 3, none, name: "gate", size: (20pt, 30pt))
  for source in ((2, 3), typ.ref("gate"), g, typ.port(g, "right")) {
    let point = source
    for _ in range(240) { point = typ.offset(point, 0.125, -0.25) }
    let actual = layout(g + typ.box(point, name: "result"))
    let expected = layout(g + typ.box(typ.offset(source, 30, -60), name: "result"))
    assert(pair-close(xy(named(actual, "result")), xy(named(expected, "result"))))
    let moved = layout(typ.group(rotate: 37deg, scale: 1.7, pivot: (1, -2), g + typ.box(point, name: "result")))
    let moved-expected = layout(typ.group(rotate: 37deg, scale: 1.7, pivot: (1, -2), g + typ.box(typ.offset(source, 30, -60), name: "result")))
    assert(pair-close(xy(named(moved, "result")), xy(named(moved-expected, "result"))))
  }
}
