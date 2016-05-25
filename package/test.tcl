#
# Test code for swift-tcl scaffold generator
#
if [file exists scaffolder.tcl] {
  source scaffolder.tcl
  proc hint {args} {
    uplevel 1 ::swift::hint {*}$args
  }
} else {
  proc hint {args} {}
}

source impork.tcl

puts [::swift::gen impork]

