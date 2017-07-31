UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
    EXTRA_SWIFTLINK=
    TARGET = .build/debug/libSwiftTcl.so
endif

ifeq ($(UNAME_S),Darwin)
    TCLVERSION=8.6.6_2
    BREWROOT=/usr/local/Cellar
    TCLLIBPATH=$(BREWROOT)/tcl-tk/$(TCLVERSION)/lib
    TCLINCPATH=$(BREWROOT)/tcl-tk/$(TCLVERSION)/include
    EXTRA_SWIFTLINK=-Xlinker -L/usr/local/lib \
        -Xlinker -L$(TCLLIBPATH) \
        -Xcc -I$(TCLINCPATH)
    TARGET = .build/debug/libSwiftTcl.dylib
endif

default: $(TARGET)

$(TARGET): Package.swift Makefile
	swift build $(EXTRA_SWIFTLINK)

SwiftTcl.xcodeproj: Package.swift Makefile build
	swift package $(EXTRA_SWIFTLINK) generate-xcodeproj
	@echo "NOTE: You will need to manually set the working directory for the SwiftTclDemo scheme to the root directory of this tree."
	@echo "Thanks Apple"

ifeq ($(UNAME_S),Linux)
install: $(TARGET)
	cp $(TARGET) /usr/lib/x86_64-linux-gnu
	ldconfig /usr/lib/x86_64-linux-gnu/libSwiftTcl.so
endif

ifeq ($(UNAME_S),Darwin)
install: $(TARGET)
	cp $(TARGET) /usr/local/lib
endif

clean:
	rm -rf $(TARGET) .build Package.pins
