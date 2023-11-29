
/// NodeFixator describes allowed movement of a node.
/// h — horisontal, v — vertical, t — turn
enum NodeFixator {
    hvt,
    hv,
    ht,
    vt,
    h,
    t,
    v,
    disabled,
}


enum BeamSection {
    arbitrary,
    rect,
    round,
}
