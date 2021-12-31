#!/bin/bash


script=$(readlink -f $0)
scriptPath=`dirname $script`

name=tidal
arch=armhf

commit=`git rev-parse  HEAD`
localChanges=`git status --porcelain`
unpushedChanges=`git cherry -v`
lastTagCommit=`git rev-list --tags --no-walk --max-count=1`
changesSinceLastTag=`git rev-list $lastTagCommit..HEAD --count`

build=$(mktemp -d)


echo "Changes since last tag ${changesSinceLastTag}"


if [ -n "$localChanges" ]; then
  echo "Repo has local uncomitted changes, not making package"
#  exit 2
fi

if [ "$branch" = "HEAD" ]; then
  echo "Repo is in a detached head state, not making package"
#  exit 2
fi

if [ -n "$unpushedChanges" ]; then
  echo "Repo has local unpushed changes, not making package"
#  exit 2
fi

if [ "$changesSinceLastTag" != "0" ]; then
  echo "Repo has ${changesSinceLastTag} changes since last tag, this is NOT a Correctly versioned build"
  echo "Package version will be UGLY and this CAN NOT be pushed to an APT repo"
fi




version=$(git describe --tags)
pkgname="${name}_${version}_${arch}"
pkgfolder="${build}/${pkgname}"

if [ -d $pkgfolder ]; then
    rm -rf $pkgfolder
fi
cp -r $scriptPath/package $pkgfolder


sed -i "s/NAME/${name}/g" $pkgfolder/DEBIAN/control
sed -i "s/VERSION/${version}/g" $pkgfolder/DEBIAN/control
sed -i "s/ARCH/${arch}/g" $pkgfolder/DEBIAN/control

dpkg-deb --build $pkgfolder

finalloc=/srv/build
mv $pkgfolder.deb $finalloc

echo "package    :  ${finalloc}/${pkgname}.deb"
echo "install    :  sudo apt -y install ${finalloc}/${pkgname}.deb"
echo "reinstall  :  sudo apt -y purge ${name} ; sudo apt -y install ${finalloc}/${pkgname}.deb"
echo "purge      :  sudo apt -y purge   ${name}"
echo ""




