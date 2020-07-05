#!/bin/bash

declare -a architectures=("arm32v7" "arm64v8" "amd64")
declare -a servermodes=("classic" "renewal")
declare -a packetversions=("" "20180418")

# Get the current version of the Hercules submodule
cd hercules-src
GIT_VERSION=`git describe --tags --exact-match 2> /dev/null || git symbolic-ref -q --short HEAD || git rev-parse --short HEAD`
cd ..

for mode in "${servermodes[@]}"; do
    for packetver in "${packetversions[@]}"; do
        for arch in "${architectures[@]}"; do
            DOCKER_TAG=hercules:${GIT_VERSION}-${mode}-${packetver:-default}

            echo "Building Hercules ${GIT_VERSION} in ${mode} mode for client ${packetver:-default} on ${arch}."
            ARCH=${arch} HERCULES_SERVER_MODE=${mode} HERCULES_PACKET_VERSION=${packetver} docker-compose up
            if [[ $? -eq 0 ]]; then
                echo "Building Docker image for hercules_${mode}_packetver-${packetver:-default}_${arch}..."
                cd hercules_${mode}_packetver-${packetver:-default}_${arch}
                docker build . --tag=${DOCKER_TAG}-${arch}
                echo "Pushing image to Docker Hub as florianpiesche:${DOCKER_TAG}-${arch}"
                docker push florianpiesche/${DOCKER_TAG}-${arch}
                docker manifest create --amend florianpiesche/${DOCKER_TAG}-latest florianpiesche/${DOCKER_TAG}-${arch}
                cd ..
            else
                echo "BUILD FAILED"
                exit 1
            fi
        done
    done
done

docker manifest push --purge florianpiesche/hercules-${mode}-${packetver}:latest
