BUILD_TYPE=$1
ZSTACK=$2
ZSTACK_AGENT=$3
ZSTACK_UTILITY=$4
ZSTACK_DASHBOARD=$5
MEVOCO_UI=$6
PREMIUM=$7
ZSTACK_STORE=$8
ZSTACK_VYOS=$9
ZSTACK_DISTRO=${10}

cd ${WORKSPACE}/

rm -rf ${BUILD_TYPE} ${BUILD_TYPE}_build_number.txt
echo ${BUILD_NUMBER} > ${BUILD_TYPE}_build_number.txt
cd ${WORKSPACE}/
mkdir -p ${BUILD_TYPE}/${BUILD_NUMBER}

mkdir -p zstack-woodpecker
tar -x -C zstack-woodpecker -f zstack-woodpecker.tar
rm -rf zstack.tar zstack-utility.tar
if [ "${ZSTACK}" != "" -a ! -d zstack ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack git@github.com:zstackio/zstack.git
fi
cd zstack
git checkout -f `git rev-list -1 HEAD`
if [ "`echo ${ZSTACK} | awk '{print $2}'`" != "" ]; then
        ZSTACK_REPO="git@github.com:zstackorg/zstack.git"
	ZSTACK_BRANCH=`echo ${ZSTACK} | awk '{print $2}'`
        PULL_NUM=`echo ${ZSTACK} | awk '{print $1}'`
        git fetch origin +${ZSTACK_BRANCH}:master
        git fetch origin +pull/${PULL_NUM}/head:need_to_merge
        git checkout -f master
        git rebase --abort || echo "No rebase in progress" 
       	rm -rf .git/rebase-.*/ || echo "Remove fail"
        git rebase need_to_merge
         
else
	git fetch origin +${ZSTACK}:master
        git checkout -f master
fi
git log  -5
#tar cfp ../zstack.tar .
echo -n "zstack: " > ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
git log -1 --pretty=oneline > ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
#if [ "${BUILD_TYPE}" == "zstack_ci" -o "${BUILD_TYPE}" == "zstack_1.0.x" -o "${BUILD_TYPE}" == "zstack_meilei_ansible" ]; then
#	sed -i /\<module\>test/d pom.xml
#	sed -i /\<module\>premium/d pom.xml
#fi
cd ..
if [ "${ZSTACK_AGENT}" != "" -a ! -d zstack-agent ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-agent git@github.com:zxwing/zstack-agent.git
fi

if [ -d zstack-agent ]; then
	cd zstack-agent
	git checkout -f `git rev-list -1 HEAD`
	git config --local credential.username quarkonics
#	git config --local credential.helper store
	if [ "`echo ${ZSTACK_AGENT} | awk '{print $2}'`" != "" ]; then
		ZSTACK_AGENT_REPO=`echo ${ZSTACK_AGENT} | awk '{print $1}'`
		ZSTACK_AGENT_BRANCH=`echo ${ZSTACK_AGENT} | awk '{print $2}'`
		git fetch ${ZSTACK_AGENT_REPO} +${ZSTACK_AGENT_BRANCH}:master
	else
		git fetch origin +${ZSTACK_AGENT}:master
	fi
	git checkout -f master
	echo -n "zstack-agent: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
        git log  -5
	cd ..
fi

if [ "${ZSTACK_STORE}" != "" -a ! -d zstack-store ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-store git@github.com:zstackio/zstack-store.git
fi


if [ -d zstack-store ]; then
	cd zstack-store
	git checkout -f `git rev-list -1 HEAD`
	git config --local credential.username quarkonics
#	git config --local credential.helper store
	if [ "`echo ${ZSTACK_STORE} | awk '{print $2}'`" != "" ]; then

		ZSTACK_STORE_REPO="git@github.com:zstackio/zstack-store.git"
		ZSTACK_STORE_BRANCH=`echo ${ZSTACK_STORE} | awk '{print $2}'`
		PULL_NUM=`echo ${ZSTACK_STORE} | awk '{print $1}'`
                git fetch origin +${ZSTACK_STORE_BRANCH}:master
                git fetch origin +pull/${PULL_NUM}/head:need_to_merge
                git checkout -f master
        	git rebase --abort || echo "No rebase in progress"
       		rm -rf .git/rebase-.*/ || echo "Remove fail"
                git rebase need_to_merge

	else
		git fetch origin +${ZSTACK_STORE}:master
	        git checkout -f master
	fi
	echo -n "zstack-store: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
        git log  -5
	cd ..
fi

if [ "${ZSTACK_VYOS}" != "" -a ! -d zstack-vyos ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-vyos git@github.com:zstackio/zstack-vyos.git
fi

if [ -d zstack-vyos ]; then
	cd zstack-vyos
	git checkout -f `git rev-list -1 HEAD`
	git config --local credential.username quarkonics
#	git config --local credential.helper store
	if [ "`echo ${ZSTACK_VYOS} | awk '{print $2}'`" != "" ]; then
		ZSTACK_VYOS_REPO="git@github.com:zstackio/zstack-vyos.git"
		ZSTACK_VYOS_BRANCH=`echo ${ZSTACK_VYOS} | awk '{print $2}'`
		PULL_NUM=`echo ${ZSTACK_VYOS} | awk '{print $1}'`
                git fetch origin +${ZSTACK_VYOS_BRANCH}:master
                git fetch origin +pull/${PULL_NUM}/head:need_to_merge
                git checkout -f master
        	git rebase --abort || echo "No rebase in progress"
       		rm -rf .git/rebase-.*/ || echo "Remove fail"
                git rebase need_to_merge

	else
		git fetch origin +${ZSTACK_VYOS}:master
	        git checkout -f master
	fi
	echo -n "zstack-vyos: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
        git log -5
	cd ..
fi


if [ "${ZSTACK_DISTRO}" != "" -a ! -d zstack-distro ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-distro git@github.com:zstackio/zstack-distro.git
fi

if [ -d zstack-distro ]; then
	cd zstack-distro
	git checkout -f `git rev-list -1 HEAD`
	git config --local credential.username quarkonics
#	git config --local credential.helper store
	if [ "`echo ${ZSTACK_DISTRO} | awk '{print $2}'`" != "" ]; then
		ZSTACK_DISTRO_REPO="git@github.com:zstackio/zstack-distro.git"
		ZSTACK_DISTRO_BRANCH=`echo ${ZSTACK_DISTRO} | awk '{print $2}'`
		PULL_NUM_=`echo ${ZSTACK_DISTRO} | awk '{print $1}'`
                git fetch origin +${ZSTACK_DISTRO_BRANCH}:master
                git fetch origin +pull/${PULL_NUM}/head:need_to_merge
                git checkout -f master
        	git rebase --abort || echo "No rebase in progress"
       		rm -rf .git/rebase-.*/ || echo "Remove fail"
                git rebase need_to_merge
	else
		git fetch origin +${ZSTACK_DISTRO}:master
                git checkout -f master
	fi
	echo -n "zstack-distro: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
        git log  -5
	cd ..
fi

if [ "${ZSTACK_UTILITY}" != "" -a ! -d zstack-utility ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-utility git@github.com:zstackio/zstack-utility.git
fi

cd zstack-utility
git clean -xdf
git checkout -f `git rev-list -1 HEAD`
if [ "`echo ${ZSTACK_UTILITY} | awk '{print $2}'`" != "" ]; then
	ZSTACK_UTILITY_REPO="git@github.com:zstackio/zstack-utility.git"
	ZSTACK_UTILITY_BRANCH=`echo ${ZSTACK_UTILITY} | awk '{print $2}'`
        PULL_NUM=`echo ${ZSTACK_UTILITY} | awk '{print $1}'`
        git fetch origin +${ZSTACK_UTILITY_BRANCH}:master
        git fetch origin +pull/${PULL_NUM}/head:need_to_merge
        git checkout -f master
        git rebase --abort || echo "No rebase in progress"
       	rm -rf .git/rebase-.*/ || echo "Remove fail"
        git rebase need_to_merge

else
	git fetch origin +${ZSTACK_UTILITY}:master
        git checkout -f master
fi

tar cfp ../zstack-utility.tar .
echo -n "zstack-utility: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
git log  -5
cd ..


if [ "${MEVOCO_UI}" != "" -a ! -d mevoco-ui ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/mevoco-ui git@github.com:zstackio/mevoco-ui.git
fi

if [ -d mevoco-ui ]; then
	cd mevoco-ui
	git checkout -f `git rev-list -1 HEAD`
	if [ "`echo ${MEVOCO_UI} | awk '{print $2}'`" != "" ]; then
		MEVOCO_UI_REPO="git@github.com:zstackio/mevoco-ui.git"
		MEVOCO_UI_BRANCH=`echo ${MEVOCO_UI} | awk '{print $2}'`
		PULL_NUM=`echo ${MEVOCO_UI} | awk '{print $1}'`
                git fetch origin +${MEVOCO_UI__BRANCH}:master
                git fetch origin +pull/${PULL_NUM}/head:need_to_merge
                git checkout -f master
        	git rebase --abort || echo "No rebase in progress"
       		rm -rf .git/rebase-.*/ || echo "Remove fail"
                git rebase need_to_merge

	else
		git fetch origin +${MEVOCO_UI}:master
		git checkout -f master
	fi

	echo -n "mevoco-ui: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
#	if [ "${BUILD_TYPE}" == "mevoco_ci" ]; then
#		sudo chown -R jenkins:jenkins .
#		sudo chown -R $(whoami) ~/.npm
		rm -rf src/bower_components
		ln -s ../../../../bower_components src/bower_components
		rm -rf zstack_dashboard/static
#		ssh root@localhost "`pwd`/install_build_env_on_centos.sh"
		PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin /bin/bash build.sh
#		sudo chown -R jenkins:jenkins .
#	fi
	git log  -5
	cd ..
fi
if [ "${ZSTACK_DASHBOARD}" != "" -a ! -d zstack-dashboard ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/zstack-dashboard git@github.com:zstackio/zstack-dashboard.git
fi

if [ -d zstack-dashboard ]; then
	cd zstack-dashboard
	git checkout -f `git rev-list -1 HEAD`
	if [ "`echo ${ZSTACK_DASHBOARD} | awk '{print $2}'`" != "" ]; then
		ZSTACK_DASHBOARD_REPO="git@github.com:zstackio/zstack-dashboard.git"
		ZSTACK_DASHBOARD_BRANCH=`echo ${ZSTACK_DASHBOARD} | awk '{print $2}'`
        	PULL_NUM=`echo ${ZSTACK_DASHBOARD} | awk '{print $1}'`
        	git fetch origin +${ZSTACK_DASHBOARD_BRANCH}:master
        	git fetch origin +pull/${PULL_NUM}/head:need_to_merge
		git rebase --abort || echo "No rebase in progress"
		rm -rf .git/rebase-.*/ || echo "Remove fail"
        	git checkout -f master
        	git rebase need_to_merge

	else
		git fetch origin +${ZSTACK_DASHBOARD}:master
		git checkout -f master
	fi
	echo -n "zstack-dashboard: " >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
	git log  -5
	cd ..
fi

if [ "${PREMIUM}" != "" -a ! -d zstack/premium ]; then
	git clone --reference ${JENKINS_HOME}/git_reference/premium git@github.com:zstackio/premium.git
	mv premium zstack
fi

if [ -d zstack/premium ]; then
	cd zstack/premium
	git checkout -f `git rev-list -1 HEAD`
	if [ "`echo ${PREMIUM} | awk '{print $2}'`" != "" ]; then
		PREMIUM_REPO="git@github.com:zstackio/premium.git"
		PREMIUM_BRANCH=`echo ${PREMIUM} | awk '{print $2}'`
		PULL_NUM=`echo ${PREMIUM} | awk '{print $1}'`
        	git fetch origin +${PREMIUM_BRANCH}:master
        	git fetch origin +pull/${PULL_NUM}/head:need_to_merge
        	git checkout -f master
        	git rebase --abort || echo "No rebase in progress"
        	rm -rf .git/rebase-.*/ || echo "Remove fail"
        	git rebase need_to_merge

	else
		git fetch origin +${PREMIUM}:master
		git checkout -f master
	fi

	echo -n "premium: " >> ../../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --format="%h %cr %an: %s" >> ../../${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt
	git log -1 --pretty=oneline >> ../../${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt
	git log  -5
	cd ../..
fi

#CHECKSUM=`md5sum ${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt | awk '{print $1}'`
#OLD_CHECKSUM=`md5sum versions.oneline.txt | awk '{print $1}'`
#if [ "${CHECKSUM}" == "${OLD_CHECKSUM}" ]; then
#	echo Already build before
#	exit 127
#fi
#scp versions.txt versions.txt.old || echo ignore failure
#scp versions.oneline.txt versions.oneline.txt.old || echo ignore failure
#scp ${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt versions.txt
#scp ${BUILD_TYPE}/${BUILD_NUMBER}/versions.oneline.txt versions.oneline.txt

rm -rf apache-tomcat-7.0.35.zip
ln -s ${JENKINS_HOME}/apache-tomcat-7.0.35.zip .
rm -rf apache-cassandra-2.2.3-bin.tar.gz
ln -s ${JENKINS_HOME}/apache-cassandra-2.2.3-bin.tar.gz .
rm -rf kairosdb-1.1.1-1.tar.gz
ln -s ${JENKINS_HOME}/kairosdb-1.1.1-1.tar.gz .

cd zstack
#mvn -DskipTests clean install
cd ..
#cp ${JENKINS_HOME}/apache-cassandra-2.2.3-bin.tar.gz .
#cp ${JENKINS_HOME}/kairosdb-1.1.1-1.tar.gz .
cd zstack-utility/zstackbuild
rm -rf centos7_repo.tar
ln -s ${JENKINS_HOME}/centos7_repo.tar .
tar xf centos7_repo.tar
rm -rf centos7_repo.tar
export GOROOT=/usr/local/golang
export GO15VENDOREXPERIMENT=1
ORIGINAL_PRODUCT_VERSION=`cat build.properties|grep product.version|awk -F '=' '{print $2}'`
TIME_STAMP=`date +"%y%m%d"`
#ant -Dzstack_build_root=${WORKSPACE} -Dzstackdashboard.build_version=master offline-centos7
BIN_VERSION='dev'
MEVOCO_BUILD=no
echo ${BUILD_TYPE} |grep zstack || MEVOCO_BUILD=yes
if [ "${MEVOCO_BUILD}" == "yes" ]; then
	PRODUCT_NAME="mevoco"
else
	PRODUCT_NAME="zstack"
fi

BIN_NAME="${PRODUCT_NAME}-installer"
if [ "${MEVOCO_BUILD}" == "yes" ]; then
	ant ${BUILD_HAMI_OPTION} -Dzstack_build_root=${WORKSPACE} -Dbuild_war_flag=premium -Dbin.version=${BIN_VERSION}-${TIME_STAMP}-${BUILD_NUMBER} -Dzstackdashboard.build_version=master -Dbuild.num=${BUILD_NUMBER} -Dproduct.name=${PRODUCT_NAME} -Dproduct.bin.name=${BIN_NAME} all-in-one
else
	ant -Dzstack_build_root=${WORKSPACE} -Dbin.version=${BIN_VERSION}-${TIME_STAMP}-${BUILD_NUMBER} -Dzstackdashboard.build_version=master -Dbuild.num=${BUILD_NUMBER} -Dproduct.name=${PRODUCT_NAME} -Dproduct.bin.name=${BIN_NAME} all-in-one
fi
ant build-testconf -Dzstack_build_root=${WORKSPACE}
ant buildtestagent -Dzstack_build_root=${WORKSPACE}

cp -r target/woodpecker/ woodpecker/
cp target/*.bin zstack-installer.bin
tar cf zstack-all-in-one.tar woodpecker/zstacktestagent.tar.bz woodpecker/conf/zstack.properties zstack-installer.bin

cd ../../
BIN_NAME=$(basename `ls zstack-utility/zstackbuild/target/*.bin`)
#cp zstack-utility/zstackbuild/target/*.bin ${BUILD_TYPE}/${BUILD_NUMBER}/
#cp zstack-utility/zstackbuild/target/zstack.war ${BUILD_TYPE}/${BUILD_NUMBER}/
#cp zstack-utility/zstackbuild/zstack-all-in-one.tar ${BUILD_TYPE}/${BUILD_NUMBER}/
#cp zstack-utility.tar ${BUILD_TYPE}/${BUILD_NUMBER}/

echo "<html>" > ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "<head>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "<title>${BUILD_TYPE} ${BIN_VERSION}-${TIME_STAMP}-${BUILD_NUMBER}</title" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "<body>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "<table border=1>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "<tr>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "    <th>${BUILD_TYPE}</th>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "    <th><a href=${BIN_NAME}>${BIN_NAME}</a></th>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "    <th></th>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "</tr>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html

for i in $(seq `wc -l ${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt|awk '{print $1}'`); do
	COMPONENT=`sed -n "${i}p" ${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt | awk '{print $1}'`
	COMMIT=`sed -n "${i}p" ${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt | awk '{print $2}'`
	SUBJECT=`sed -n "${i}p" ${BUILD_TYPE}/${BUILD_NUMBER}/versions.txt | awk '{for (i=3; i<NF; i++) printf("%s ",$i);print $i}'`
	echo "<tr>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
	echo "    <td>${COMPONENT}</td>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
	echo "    <td>${COMMIT}</td>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
	echo "    <td>${SUBJECT}</td>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
	echo "</tr>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
done
echo "</table>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "</body>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html
echo "</html>" >> ${BUILD_TYPE}/${BUILD_NUMBER}/index.html

rm -rf ${BUILD_TYPE}/latest
ln -s ${BUILD_NUMBER} ${BUILD_TYPE}/latest
if [ "${MEVOCO_BUILD}" == "yes" ]; then
	ln -s ${BIN_NAME} ${BUILD_TYPE}/latest/mevoco-installer.bin
else
	ln -s ${BIN_NAME} ${BUILD_TYPE}/latest/zstack-installer.bin
fi
#if [ "${bat}" != "no" ]; then
#	echo 1 > run_bat
#else
#	echo 0 > run_bat
#fi
