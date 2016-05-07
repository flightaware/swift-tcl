

In the packages directory is scaffolder.tcl.  It has code to marshall all the procs (swift::enumerate_procs).  swift::gen generates a Swift function definition for the proc by examining its arguments and default values.

For a given proc name, swift::gen attempts to infer the data types of the arguments by examining their defaults and emits a Swift function declaration that will invoke the Tcl springboard so that the Tcl proc is a native function in Swift.

It can recognize Int, Double, Bool and String.

There are a few problems, though…

* Tcl developers tend to use 0 for default values for booleans so we guess Int instead of Bool.
* If a function argument doesn’t take a default value then we just say it’s String.
* We can pretty much see if the proc returns something but we only guess that it’s a String.

Consequently there is a hinting system.  Right now you can say “swift::hint photos_display_hot_rating starWidth Int -> String”

What it takes as an argument is the proc name and then key-value pairs for the overrides for any proc arguments.  The special string “->” defines the return type.

I think these hints ultimately belong in comments in the source code.

I have been toying with that possibly not every proc needs to be directly accessible from Swift (but maybe it would be best if it did?).  I am also toying with the idea that you might bite the bullet and include a full Swift declaration for the proc inside the comments.

```tcl
proc flightaware_photos_displayWidget {compare sort {limit 6} {context default} {style default} {photos_period 0} {dryrun 0}} {...}
```


```
 % swift::gen flightaware_photos_displayWidget
 func ::fa_community_media::flightaware_photos_displayWidget (compare: String, sort: String, limit: Int = 6, context: String = "default", style: String = "default", photos_period: Int = 0, dryrun: Int = 0 -> String) {
     return tcl_springboard(springboardInterp, "flightaware_photos_displayWidget", string_to_tclobjp(compare), string_to_tclobjp(sort), Tcl_NewLongObj(limit), string_to_tclobjp(context), string_to_tclobjp(style), Tcl_NewLongObj(photos_period), Tcl_NewLongObj(dryrun))
}
```

In the above example *dryrun* should have been a Bool, consequently we tell the hinter...  ``` % swift::hint flightaware_photos_displayWidget dryrun Bool ``` to produce

```tcl
func flightaware_photos_displayWidget (compare: String, sort: String, limit: Int = 6, context: String = "default", style: String = "default", photos_period: Int = 0, dryrun: Bool = 0 -> String) {
    return tcl_springboard(springboardInterp, "flightaware_photos_displayWidget", string_to_tclobjp(compare), string_to_tclobjp(sort), Tcl_NewLongObj(limit), string_to_tclobjp(context), string_to_tclobjp(style), Tcl_NewLongObj(photos_period), Tcl_NewBooleanObj(dryrun ? 1 : 0))
}
```

A tricky issue is going to be passing Swift objects around in Tcl.  I think it will be possible to accept objects possibly as the AnyObject type and get the object type as a string from Swift.  Definitely there is a way to get the unsafeAddressOf something so an instance of an object that in Swift may not have any kind of name can have a name in Tcl consisting of the object type concatenated with the address of the object as a string, a lot like Swig does for bringing C and C++ stuff to Tcl in an automated way.
