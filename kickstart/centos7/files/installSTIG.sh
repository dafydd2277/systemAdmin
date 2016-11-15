#! /bin/bash
#
# installSTIG.sh
#
# Install the STIG tests, and run them.

mkdir ${d_stig}
pushd ${d_stig}

/usr/bin/wget ${s_stig_source}
/usr/bin/wget ${s_stig_viewer_source}

# Run the jar with `java -jar ${s_viewer}.jar`, substituting as appropriate.

mkdir -p ${s_stig}
cd ${s_stig}
unzip ../${s_stig}.zip

df_cpe=${s_stig}-cpe-dictionary.xml

sed --in-place=.orig \
  's/<Group\ \(.*\)/<Group\ selected="false"\ \1/g' \
  ${s_stig}-xccdf.xml

sed --in-place \
"s#<platform>Red Hat Enterprise Linux 6</platform>#<platform>CentOS 6</platform>##g" \
${s_stig}-cpe-oval.xml

sed --in-place \
"s#cpe:/o:redhat:enterprise_linux:6#cpe:/o:centos:centos:6##g" \
${s_stig}-cpe-oval.xml

sed --in-place \
"s#cpe:/o:redhat:enterprise_linux#cpe:/o:centos:centos##g" \
${s_stig}-xccdf.xml


oscap xccdf resolve \
  --output ${s_stig}_Resolved-xccdf.xml \
  ${s_stig}-xccdf.xml

oscap xccdf generate guide \
  --profile MAC-1_Classified \
  --output ../RHEL6_Guide.html \
  ${s_stig}_Resolved-xccdf.xml

oscap xccdf eval \
  --profile MAC-1_Classified \
  --check-engine-results \
  --results ../Hard_Install_Results.xml \
  --report ../Hard_Install_Results.html \
  --cpe ${df_cpe} \
  ${s_stig}_Resolved-xccdf.xml \
  >../Hard_Install_STDOUT.txt 2>&1

