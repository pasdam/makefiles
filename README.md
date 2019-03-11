# makefiles

This repository contains a collections of makefiles with utility targets common to different projects.

Each makefile and each target in them have a brief comment on top, with the requirements and the usage description.

At the moment the repository contains the following:

* [docker.mk](docker.mk): contains targets to simplify the build and run of docker images;
* [go.mk](go.mk): contains targets to use for [Go](https://golang.org/) projects;
* [go.mod.mk](go.mod.mk): contains targets to use specifically for [Go](https://golang.org/) projects with supports for [modules](https://github.com/golang/go/wiki/Modules);
* [go.mod.vendor.mk](go.mod.vendor.mk): contains targets to use specifically for [Go](https://golang.org/) projects with supports for [modules](https://github.com/golang/go/wiki/Modules) and vendoring;
* [help.mk](help.mk): contains a target to automatically generate a help description for all the targets;
