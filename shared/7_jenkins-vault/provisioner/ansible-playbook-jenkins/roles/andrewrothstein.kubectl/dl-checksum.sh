#!/usr/bin/env sh
VER=v1.13.2
DIR=~/Downloads
MIRROR=https://storage.googleapis.com/kubernetes-release/release/$VER/bin

dl()
{
    OS=$1
    PLATFORM=$2
    SUFFIX=${3:-}
    wget -O $DIR/kubectl-$OS-$PLATFORM-$VER $MIRROR/$OS/$PLATFORM/kubectl$SUFFIX
}

dl linux amd64
dl linux arm64
dl darwin amd64
dl windows amd64 .exe
sha256sum $DIR/kubectl-*-$VER

