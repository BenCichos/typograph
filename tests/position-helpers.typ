#import "/src/position-layout.typ": prepare-nodes, resolve-positions
#let close(a, b) = calc.abs(a - b) < 1e-8
#let pair-close(a, b) = a.zip(b).all(pair => close(..pair))
#let layout(items, unit: 1cm, size-factor: 1, port-spacing: 7pt, presets: (:), overrides: (:), font-size: auto) = {
  let pending = ()
  let work = ()
  for item in items {
    if item.type == "node" { pending.push(item) }
    else {
      work.push(item)
      if item.type == "edge" {
        for wp in item.waypoints { if wp.node != none { pending.push(wp.node) } }
      }
    }
  }
  let collection = prepare-nodes(pending, work, presets: presets, overrides: overrides,
    size-factor: size-factor, port-spacing: port-spacing, font-size: font-size)
  resolve-positions(collection, unit, size-factor: size-factor, port-spacing: port-spacing)
}
#let named(result, name) = result.nodes.find(n => n.name == name)
#let xy(node) = (node.x, node.y)
