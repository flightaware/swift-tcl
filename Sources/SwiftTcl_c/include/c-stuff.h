//
//  c-stuff.h
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

#ifndef c_stuff_h
#define c_stuff_h

#include <stdio.h>
#if defined(__linux__)
#include "/usr/include/tcl/tcl.h"
#else
#include "tcl.h"
#endif

void DecrRefCount(Tcl_Obj *obj);
void IncrRefCount(Tcl_Obj *obj);

#endif /* c_stuff_h */
