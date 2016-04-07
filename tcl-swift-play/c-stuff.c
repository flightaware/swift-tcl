//
//  c-stuff.c
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

#include "c-stuff.h"

void DecrRefCount(Tcl_Obj *obj) {
    if (--(obj)->refCount <= 0) {
        TclFreeObj(obj);
    }
}
