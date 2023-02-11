# Overview

This repository contains build scripts used for building external libraries that are bundled with strawberry perl.

It is intended to be used as part of a larger process via a docker container.  That container will install all the requisite libraries and tools for the build process, as well as generate the appropriate directories.  See details at https://github.com/StrawberryPerl/spbuild .

If you wish to replicate build systems for older versions of Strawberry perl then see the README file under the archive directory of this repository.  

Below is some general information about the system for those wishing to try different options or build their own verisons of the libraries. 

# Building libraries using job files

The set of libraries to build is specified using a job file.  This lists the name and version of the libraries to build.  There is currently no dependency tracking so you will need to ensure all dependencies have already been built or downloaded into the ```_out``` directory.  

The job file is passed as the first argument to the build script.  The second argument is the DLL suffix (see below).

```
$ ./build.sh 5034 __
```

If you wish to build a different version of a library then ensure its URL is listed in the ```sources.list``` file and that the name in the build script matches the basename of the URL, without any file type extensions.  For example ```tiff-4.5.0``` in the job file corresponds with ```http://download.osgeo.org/libtiff/tiff-4.5.0.tar.gz``` in ```sources.list```.  

By default, any existing build artefacts in the ```_out``` directory are reused to speed up the build process.  If you wish to rebuild all libraries then delete the ```_out``` directory or set an environment variable ```REBUILD_ALL``` to a true value before calling ```build.sh```.

If you wish to rebuild individual libs then append ```rebuild``` to their entries in the job file.  For example this simplified job file will rebuild gdbm-1.23 but not db-6.2.38 if it already exists in ```_out```.

```
###### gddm + db
gdbm-1.23 rebuild
db-6.2.38
``` 


#  DLL naming convention

One point that is worth noting is that DLLs built using this system have a suffix appended to the name.  This is so they are less likely to clash with other versions of those DLLs that have already been loaded, and which may be incompatible.  The 64-bit builds use two underscores by default, for example ```libpong__.dll```, while the 32-bit builds use a single underscore (```libpong_.dll```).  Note that this suffix needs to be passed as an argument to the ```build.sh``` call or no suffix is appended.

The DLL suffix is probably the point of greatest complexity for the build system, especially for cmake builds.  A [patchelf](https://github.com/NixOS/patchelf) equivalent for PE32 files would  greatly simplify the whole process.  
