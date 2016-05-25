
proc impork {file} {
  if [catch {open $file} status] {
    return {}
  }
  set fp $status
  set contents [read $fp]
  close $fp
  set result {}
  set ln 0
  foreach line [split $contents "\n"] {
    incr ln
    lappend result $ln $line
  }
  return $result
}
