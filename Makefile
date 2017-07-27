#
# tcl library path for brew - needs to be parameterized somehow
#
# version for TCL brew package
TCLVERSION=8.6.6_2
BREWROOT=/usr/local/Cellar
TCLLIBPATH=$(BREWROOT)/tcl-tk/$(TCLVERSION)/lib
TCLINCPATH=$(BREWROOT)/tcl-tk/$(TCLVERSION)/include

BUILD=./.build

default: SwiftTcl.xcodeproj

build: $(BUILD)

$(BUILD): Package.swift Makefile
	swift build -Xlinker -L$(TCLLIBPATH) -Xlinker -ltcl8.6 -Xlinker -ltclstub8.6 -Xlinker -lz -Xcc -I$(TCLINCPATH)

SwiftTcl.xcodeproj: Package.swift Makefile build
	swift package -Xlinker -L$(TCLLIBPATH) -Xlinker -ltcl8.6 -Xlinker -ltclstub8.6 generate-xcodeproj
	@echo "NOTE: You will need to manually set the working directory for the SwiftTclDemo scheme to the root directory of this tree."
	@echo "Thanks Apple"
