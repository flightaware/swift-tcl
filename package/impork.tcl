
proc impork {file {first 1} {step 1}} {
  if [catch {open $file} status] {
    return {}
  }
  set fp $status
  set contents [read $fp]
  close $fp
  set result {}
  set ln $first
  foreach line [split $contents "\n"] {
    lappend result $ln $line
    incr ln $step
  }
  return $result
}
