#!/bin/bash

set -eux;

yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel

java_jre_bin=$(dirname $(readlink $(readlink $(which java))));
java_jre=${java_jre_bin%/*};
java_home=${java_jre%/*};

sed -i '$a\export JAVA_HOME='"$java_home"'\nexport PATH=$PATH:$JAVA_HOME/bin' /etc/profile;
source /etc/profile