#!/bin/bash

declare -a architectures=("arm32v7" "arm64v8" "i386" "amd64")
declare -a servermodes=("classic" "renewal")
declare -a packetversions=("" "20180418")

# Get the current release tag from the Hercules submodule
cd hercules-src
GIT_VERSION=`git describe --tags --exact-match 2> /dev/null || git symbolic-ref -q --short HEAD || git rev-parse --short HEAD`
PACKETVER_FROM_SOURCE=`cat src/common/mmo.h | sed -n -e 's/^.*#define PACKETVER \(.*\)/\1/p'`
cd ..

for mode in "${servermodes[@]}"; do
    for packetver in "${packetversions[@]}"; do
        for arch in "${architectures[@]}"; do
            DOCKER_REPO=hercules-${mode}-${packetver:-default}
            BUILD_TARGET=hercules_${mode}_packetver-${packetver:-${PACKETVER_FROM_SOURCE}}_${arch}

            echo "Building Hercules ${GIT_VERSION} in ${mode} mode for client ${packetver:-default} (default: ${PACKETVER_FROM_SOURCE}) on ${arch}."
            if [[ ! -d ${BUILD_TARGET} ]]; then
                USERID=${UID} ARCH=${arch} HERCULES_SERVER_MODE=${mode} HERCULES_PACKET_VERSION=${packetver} docker-compose up
            fi
            if [[ $? -eq 0 ]]; then
                echo "Building Docker image for hercules_${mode}_packetver-${packetver:-default}_${arch}..."
                cd ${BUILD_TARGET}
                docker build . --tag=florianpiesche/${DOCKER_REPO}:${arch} --build-arg ARCH=${arch}
                echo "Pushing image to Docker Hub as florianpiesche/${DOCKER_REPO}:${arch}"
                docker push florianpiesche/${DOCKER_REPO}:${arch}
                docker manifest create --amend florianpiesche/${DOCKER_REPO}:latest florianpiesche/${DOCKER_REPO}:${arch}

                echo "Updating README..."
                sed -i "s/__GIT_VERSION__/${GIT_VERSION}/g" README.md
                sed -i "s/__PACKET_VER__/${packetver:-$PACKETVER_FROM_SOURCE}/g" README.md
                sed -i "s/__PACKET_VER_DEFAULT__/${packetver:-default}/g" README.md
                sed -i "s/__SERVER_MODE__/$mode/g" README.md
                /usr/libexec/docker/cli-plugins/docker-pushrm docker.io/florianpiesche/${DOCKER_REPO}
                cd ..
                rm -rf ${BUILD_TARGET}
            else
                echo "BUILD FAILED"
                exit 1
            fi
        done
        docker manifest push --purge florianpiesche/hercules-${mode}-${packetver:-default}:latest
    done
done

