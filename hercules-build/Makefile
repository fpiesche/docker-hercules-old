# Assemble Dockerfiles from individual stage segments to reduce need for manual copying
Dockerfiles:
	cat docker-stages/build-hercules.docker docker-stages/archive-build.docker > Dockerfile.archive-build
	cat docker-stages/build-hercules.docker docker-stages/copy-build.docker > Dockerfile.copy-build
	cat docker-stages/build-hercules.docker docker-stages/build-all-in-one.docker > Dockerfile.all-in-one

# Create the build and archive it as a tarball
archive: Dockerfiles
	docker buildx build -f Dockerfile.archive-build -o . build

# Create the build as loose files
build: Dockerfiles
	docker buildx build -f Dockerfile.copy-build -o . build

# Build Images
all-in-one: Dockerfiles
	docker buildx build -f Dockerfile.all-in-one -t hercules-all-in-one .
