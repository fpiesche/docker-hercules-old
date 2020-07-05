#!/bin/bash

declare -a architectures=("arm32v7" "arm64v8" "amd64")
declare -a servermodes=("classic" "renewal")
declare -a packetversions=("" "20180418")

for mode in "${servermodes[@]}"; do
    for packetver in "${packetversions[@]}"; do
        for arch in "${architectures[@]}"; do
            echo "Building Hercules in ${mode} mode for client ${packetver:-default} on ${arch}."
            echo "Will register image as hercules-${mode}-${packetver:-default}:${arch}."
            ARCH=${arch} HERCULES_SERVER_MODE=${mode} HERCULES_PACKET_VERSION=${packetver} docker-compose up
            if [[ $? -eq 0 ]]; then
                cd hercules_${mode}_packetver-${packetver:-default}_${arch}
                docker build . --tag=hercules-${mode}-${packetver:-default}:${arch}
                docker push florianpiesche/hercules-${mode}-${packetver:-default}:${arch}
                docker manifest create --amend florianpiesche/hercules-${mode}-${packetver:-default}:latest florianpiesche/hercules-${mode}-${packetver:-default}:${arch}
                cd ..
            else
                echo "BUILD FAILED"
                exit 1
            fi
        done
    done
done

docker manifest push --purge florianpiesche/hercules-${mode}-${packetver}:latest
