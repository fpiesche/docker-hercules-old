# Dockerfiles for building Hercules Docker images from local build

These are intended mainly for use in GitHub Actions. The general pipeline process
for these builds is:

  * Build Hercules using `Dockerfile.copy-build`:
    * Build Hercules inside a Docker container
    * Copy finished build from build container to host
  * Build Hercules images using locally copied build:
    * Copy entire local build into a new "all-in-one" image
    * Copy only necessary files for login server to a new "login" image
    * Copy only necessary files for map server to a new "map" image
    * Copy only necessary files for char server to a new "char" image

This process guarantees that all images built at the same time are using the
exact same build, not multiple different builds made from the same source.

The reason for this is to guarantee that undetected compilation errors don't
only affect some components, increasing the likelihood for problems going
undetected; additionally doing this reduces the build time as Hercules is
only built once and then copied into the different images, rather than
each image building its own copy of Hercules.
