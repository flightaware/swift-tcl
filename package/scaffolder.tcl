



namespace eval ::swift {
	variable hints

# hint
#
# swift::hint photos_display_hot_rating starWidth Int -> String
proc hint {proc args} {
	variable hints

	set hints($proc) $args
}

proc guess_default_type {defaultValue} {
	if {[string is int -strict $defaultValue]} {
		return Int
	}

	if {[string is double -strict $defaultValue]} {
		return Double
	}

	return String
}

proc does_proc_return_something {proc} {
	set body [info body $proc]

	return [regexp {return } $body]
}

proc gen {proc} {
	variable hints

	set args [info args $proc]

	if {[info exists hints($proc)]} {
		array set myHints $hints($proc)
	}

	set string "func $proc ("
	set firstPass 1

	foreach arg $args {
		if {$firstPass} {
			set firstPass 0
		} else {
			append string ", "
		}

		if {![info default $proc $arg default]} {
			unset -nocomplain default
		}

		# if there's a hint for the type, use that,
		# else if there's a default value try to
		# sniff the type out of that else say
		# it's a String
		if {[info exists myHints($arg)]} {
			set type $myHints($arg)
		} elseif {[info exists default]} {
			set type [guess_default_type $default]
		} else {
			set type String
		}
		set myTypes($arg) $type

		append string "$arg: $type"

		if {[info exists default]} {
			if {$type == "String"} {
				append string " = \"$default\""
			} else {
				append string " = $default"
			}
		}
	}

	if {[info exists myHints(->)]} {
		append string " -> $myHints(->)"
	} else {
		if {[does_proc_return_something $proc]} {
			append string " -> String"
		}
	}

	append string ") {\n"

	set springboard "    return tcl_springboard(\"$proc\""
	foreach arg $args {
		append springboard ", "

		switch $myTypes($arg) {
			"String" {
				append springboard "string_to_tclobjp($arg)"
			}

			"Int" {
				append springboard "Tcl_NewLongObj($arg)"
			}

			"Double" {
				append springboard "Tcl_NewDoubleObj($arg)"
			}

			"Bool" {
				append springboard "Tcl_NewBooleanObj($arg ? 1 : 0)"
			}
		}
	}

	append springboard ")"

	append string "$springboard\n}"

	return $string
}




#
# enumerate_procs - recursively enumerate all procs within a namespace and
#   all of its descendant namespaces (defaulting to the top-level namespace),
#   returning them as a list
#
proc enumerate_procs {{ns ::}} {
	set list [info procs ${ns}::*]

	foreach childNamespace [namespace children $ns] {
		lappend list {*}[enumerate_procs $childNamespace]
	}

	return $list
}

}


