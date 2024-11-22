#!/bin/bash
# 1.15.4
# 4.16.13

# TODO 
# Create udev automation for NIC renaming
# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="50:7c:6f:53:ad:b8", ATTR{type}=="1", NAME="ens3f0"
# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="50:7c:6f:53:ad:b9", ATTR{type}=="1", NAME="ens3f1"
# Update URL to new Intel download
# https://downloadmirror.intel.com/832286/ice-1.15.4.tar.gz

set -eu
ICE_DRIVER_VER=$1; shift
OCP_VER=$1; shift

# Point to your local registry
REGISTRY='quay.io/dphillip'
#REGISTRY='cnfde2.ptp.lab.eng.bos.redhat.com:5000'
MIRROR='cnfde2.ptp.lab.eng.bos.redhat.com:6666'
BASE_IMAGE='registry.access.redhat.com/ubi9:latest'
DRIVER_IMAGE='oot-ice'

GET_DEVEL_RPM="no"
BUILD_RT="yes"
KERNEL_VER=""

# no longer content
MACHINE_OS=$(oc adm release info --image-for=rhel-coreos quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64)
DTK_IMAGE=$(oc adm release info --image-for=driver-toolkit quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64)
if [ ! -z ${KERNEL_VER} ]; then
  GET_DEVEL_RPM="yes"
elif [ ${BUILD_RT} == "yes" ]; then
  KERNEL_VER=$(oc image info -o json ${MACHINE_OS}  | jq -r ".config.config.Labels[\"ostree.linux\"]")
  KERNEL_VER="${KERNEL_VER}+rt"
  TAG=${REGISTRY}/${DRIVER_IMAGE}-${ICE_DRIVER_VER}:${OCP_VER}-rt
else
  KERNEL_VER=$(oc image info -o json ${MACHINE_OS}  | jq -r ".config.config.Labels[\"ostree.linux\"]")
  TAG=${REGISTRY}/${DRIVER_IMAGE}-${ICE_DRIVER_VER}:${OCP_VER}
fi


#TAG=${KERNEL_VER}

echo "DTKI for OCP-${OCP_VER} : ${DTK_IMAGE}"
echo "Building for ${KERNEL_VER}"

podman build -f Dockerfile.rhel9 --no-cache . \
  --build-arg IMAGE=${BASE_IMAGE} \
  --build-arg BUILD_IMAGE=${DTK_IMAGE} \
  --build-arg DRIVER_VER=${ICE_DRIVER_VER} \
  --build-arg KERNEL_VERSION=${KERNEL_VER} \
  --build-arg MIRROR=${MIRROR} \
  --build-arg GET_DEVEL_RPM=${GET_DEVEL_RPM} \
  -t ${TAG}

podman push --tls-verify=false ${TAG}

