// Public point syntax plus exact layout assertions (not just smoke renders).
#import "/src/lib.typ" as typ
#import "position-helpers.typ": close, pair-close, layout, named, xy

#assert(typ.box((1, 2), label: [A]) == typ.box(1, 2, label: [A]))
#assert(typ.gate((1, 2), [U]) == typ.gate(1, 2, [U]))
#assert(typ.place((1, 2), [C]) == typ.place(1, 2, [C]))
#assert(typ.make-node("custom", (1, 2)) == typ.make-node("custom", 1, 2))
#let custom = typ.node-type("custom", flippable: true)
#assert(custom((1, 2), flip: true) == custom(1, 2, flip: true))
#assert(typ.box.with(label: [A])((1, 2)) == typ.box(1, 2, label: [A]))
#assert(typ.gate.with((1, 2))([U]) == typ.gate(1, 2, [U]))
#assert(typ.gate.with(1)(2, [U]) == typ.gate(1, 2, [U]))

#context {
  let g = typ.gate(2, 3, none, name: "g", size: (20pt, 30pt),
    legs: (left: 3, right: 3, top: 3, bottom: 3))
  for side in ("left", "right", "top", "bottom") {
    for index in range(3) {
      let p = typ.port(g, side, index)
      let n = typ.box(p, name: "follower")
      let result = layout(n + typ.edge(p, typ.rel(1, 0)))
      assert(result.nodes.len() == 2, message: "position captures the gate")
      let endpoint = result.work.first().waypoints.first().end
      assert(pair-close(xy(named(result, "follower")), endpoint))
      let offset = (index - 1) * 7pt / 1cm
      let expected = if side == "left" { (2 - 10pt / 1cm, 3 + offset) }
        else if side == "right" { (2 + 10pt / 1cm, 3 + offset) }
        else if side == "top" { (2 + offset, 3 + 15pt / 1cm) }
        else { (2 + offset, 3 - 15pt / 1cm) }
      assert(pair-close(endpoint, expected))
    }
  }
  let p = typ.port(g, "right", 1)
  assert(typ.box(p) == typ.box(p.x, p.y))
  let items = {
    typ.box(typ.offset(p, 0.5, -1), name: "both", label: [A])
    typ.box(p.x, -2, name: "x-only")
    typ.box(-3, p.y, name: "y-only")
    typ.box(p.x, typ.ref("both").y, name: "mixed")
    typ.box(typ.offset(typ.offset(p, 2, -3), -1, 1), name: "nested")
    typ.place(typ.offset(p, 0, -0.5), [caption], align: left + top)
  }
  let result = layout(items)
  let px = 2 + 10pt / 1cm
  assert(pair-close(xy(named(result, "both")), (px + 0.5, 2)))
  assert(pair-close(xy(named(result, "x-only")), (px, -2)))
  assert(pair-close(xy(named(result, "y-only")), (-3, 3)))
  assert(pair-close(xy(named(result, "mixed")), (px, 2)))
  assert(pair-close(xy(named(result, "nested")), (px + 1, 1)))
  assert(pair-close(xy(result.work.first()), (px, 2.5)))
  typ.diagram(items)

  // Forward named gates are not captured: emitting one is still required.
  let future = typ.port(typ.ref("later"), "right")
  let forward = layout({
    typ.box(typ.offset(future, 1, 0), name: "follower")
    typ.gate(0, 0, [wide gate label], name: "later")
    typ.edge(future, typ.ref("follower"))
  })
  assert(close(named(forward, "follower").x, forward.work.first().waypoints.first().end.at(0) + 1))
  assert(forward.work.first().waypoints.last().clip-to == named(forward, "follower"))

  // These nodes depend on each other, but their individual axes do not cycle.
  let independent = layout({
    typ.node(typ.ref("b").x, 4, name: "a")
    typ.node(2, typ.ref("a").y, name: "b")
    typ.node(typ.ref("self").y, 7, name: "self")
  })
  assert(xy(named(independent, "a")) == (2, 4))
  assert(xy(named(independent, "b")) == (2, 4))
  assert(xy(named(independent, "self")) == (7, 7))

  let origin = typ.box(1, 2, name: "origin")
  let centered = layout(typ.box(origin, name: "centered"))
  assert(centered.nodes.len() == 2 and xy(named(centered, "centered")) == (1, 2))

  // Equal source values deduplicate; different expressions do not, even
  // when they resolve to the same visible point.
  let a = typ.node(typ.ref("origin"))
  let b = typ.node(typ.offset(typ.ref("origin"), 0, 0))
  let identities = layout(origin + a + a + b)
  assert(identities.nodes.len() == 3)

  // Long forward chains and fan-out must not recurse along node dependencies.
  let chain = ()
  for i in range(160) {
    chain += typ.node(typ.offset(typ.ref("chain-" + str(i + 1)), 1, 0), name: "chain-" + str(i))
  }
  chain += typ.node(0, 0, name: "chain-160")
  for i in range(100) { chain += typ.node(typ.ref("chain-0").x, i, name: "fan-" + str(i)) }
  let result = layout(chain)
  assert(xy(named(result, "chain-0")) == (160, 0))
  assert(xy(named(result, "fan-99")) == (160, 99))

  // Direct unnamed captures also form a DAG. Identity keys must not expand
  // its shared subgraphs into enormous repr strings, nor may group recurse
  // through every captured node on the Typst call stack.
  let direct = typ.node(0, 0)
  for i in range(80) { direct = typ.node(typ.offset(direct, 1, 0)) }
  let direct-result = layout(direct)
  assert(direct-result.nodes.len() == 81)
  assert(xy(direct-result.nodes.last()) == (80, 0))
  let moved = layout(typ.group(dx: 1, dy: -2, scale: 2, rotate: 90deg, direct))
  assert(moved.nodes.len() == 81)
  assert(pair-close(xy(moved.nodes.last()), (1, 158)))
  assert(repr(direct).len() < 200000, message: "public captures stay flat, not exponential")
}
