# Segmented stages for Dockerfiles

These are the various individual stages for Dockerfiles. As the Docker build process
involves a fair amount of duplication, the main Dockerfiles in the `hercules-build`
directory can be generated from these to remove the need to manually copy and paste
the Dockerfiles together.

To update the Dockerfiles with the latest copies of the current process from these
files, simply run `make Dockerfiles` in the `hercules-build` directory.
