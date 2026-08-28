// Additional rendering workloads for benchmark.py. No timing assertions.
#import "/src/lib.typ" as typ
#set page(width: auto, height: auto, margin: 0pt)
#let workload = sys.inputs.at("workload", default: "ports")
#let dot = typ.box.with(style: (min-size: 6pt, inset: 0pt))

#typ.diagram({
  if workload == "ports" {
    for row in range(12) {
      for col in range(12) {
        let g = typ.gate(col * 2, row, [U], size: (18pt, 12pt), legs: (left: 2, right: 2))
        for index in range(2) {
          typ.edge(typ.port(g, "left", index), typ.rel(-0.5, 0))
          typ.edge(typ.port(g, "right", index), typ.rel(0.5, 0))
        }
      }
    }
  } else if workload == "named-chain" {
    dot(0, 0, name: "n0")
    for index in range(1, 240) {
      dot(typ.offset(typ.ref("n" + str(index - 1)), 0.3, 0), name: "n" + str(index))
    }
    for index in range(160) {
      dot(typ.ref("n120").x, 1 + index * 0.3)
    }
  } else if workload == "captured-chain" {
    let last = dot(0, 0)
    for _ in range(100) { last = dot(typ.offset(last, 0.3, 0)) }
    last
  } else if workload == "grouped-axes" {
    for row in range(10) {
      for col in range(10) {
        let g = typ.gate(0, 0, [U], size: (24pt, 12pt), legs: (right: 2))
        let p = typ.port(g, "right", 1)
        typ.group(dx: col * 3, dy: row * 3, rotate: 37deg, scale: 0.8, pivot: (1, -1), {
          dot(p.x, -1)
          dot(typ.offset(p, 0.5, 0))
          typ.edge(p, typ.rel(1, 0))
        })
      }
    }
  } else { panic("unknown benchmark workload: " + workload) }
})
