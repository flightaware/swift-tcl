### Build on Linux

cd <checkout>
swift build -Xlinker -ltcl8.6

### Build on OS X with Brew

#### Brew Install
Install tcl with brew.  Get version 8.6+.

```
brew install tcl-tk
```

Brew creates pkg-config files, which Swift package manager attempts to use.  But in this case we are still not getting the correct flags for the compiler or linker. Find your brew package config file /usr/local/Cellar/tcl-tk/8.6.6_2/lib/pkgconfig/tcl.pc. Use that to get the link and include values to pass in.
```
swift build -Xlinker -L/usr/local/Cellar/tcl-tk/8.6.6_2/lib -Xlinker -ltcl8.6 -Xlinker -ltclstub8.6 -Xlinker -lz -Xcc -I/usr/local/Cellar/tcl-tk/8.6.6_2/include
```

#### Update the Tcl Framework

Install brew ... then reinstall from the Tcl source.  Brew provides the tcl8.6 needed by the installer.  You figure out other ways to get tclsh8.6 for the installer.

This allows one to build with these minimal flags for linking.
```
swift build -Xlinker -lTcl
```
And in Xcode you only need to add "Link/Other Libraries" as -lTcl

THIS WILL REMOVE YOUR Apple Tcl BUILDS!!!
```
cd tcl8.6.6/macox
./configure --enable-framework
make
sudo make -e NATIVE_TCLSH=/usr/local/bin/tclsh8.6 install
```
