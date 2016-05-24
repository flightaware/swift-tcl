#
# Apply the scaffolder to itself to test its output
#
source scaffolder.tcl

foreach proc [::swift::enumerate_procs ::swift] {
  puts [::swift::gen $proc]
}

