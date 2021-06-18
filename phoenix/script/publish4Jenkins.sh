VERSION=$1

if [[ -z $VERSION ]];then
  VERSION="0.0.1"
fi

PROJECT_ROOT="$(pwd)"

PANDORA_FOLDER_NAME=pandora
RELEASE_DIR=${PROJECT_ROOT}/distribution/release
PANDORA_EXPRESS_DIR=${RELEASE_DIR}/pandora-express
PANDORA_ROOT_DIR=${PANDORA_EXPRESS_DIR}/lib/${PANDORA_FOLDER_NAME}

export project=${PROJECT_ROOT}
ES_FOLDER_NAME=elasticsearch-6.8.0-SNAPSHOT
ES_DIST_DIR=${project}/distribution/archives/zip/build/distributions
ES_FOLDER_LIB_DIR=${ES_DIST_DIR}/${ES_FOLDER_NAME}/lib


renameBuildResult() {
  cd ${ES_FOLDER_LIB_DIR}

  if [[ -f "elasticsearch-6.8.0-SNAPSHOT.jar" ]]; then
    mv elasticsearch-6.8.0-SNAPSHOT.jar pandora.jar
  fi

  mv elasticsearch-cli-6.8.0-SNAPSHOT.jar pandora-cli.jar
  mv elasticsearch-core-6.8.0-SNAPSHOT.jar pandora-core.jar
  mv plugin-classloader-6.8.0-SNAPSHOT.jar plugin-classloader.jar
  mv java-version-checker-6.8.0-SNAPSHOT.jar java-version-checker.jar
  mv elasticsearch-launchers-6.8.0-SNAPSHOT.jar pandora-launchers.jar
  mv elasticsearch-secure-sm-6.8.0-SNAPSHOT.jar pandora-secure-sm.jar
  mv elasticsearch-x-content-6.8.0-SNAPSHOT.jar pandora-x-content.jar
  mv tools/plugin-cli/elasticsearch-plugin-cli-6.8.0-SNAPSHOT.jar tools/plugin-cli/pandora-plugin-cli.jar
}

mvPhoenixToRelease() {

  echo -e "\nMove phoenix to release path\n"
  cd ${ES_DIST_DIR}
  rm -rf ${PANDORA_FOLDER_NAME}/*
  mv ${ES_FOLDER_NAME} ${PANDORA_FOLDER_NAME}
  echo mv ${ES_DIST_DIR}/${PANDORA_FOLDER_NAME} ${PANDORA_EXPRESS_DIR}/lib
  rm -rf ${PANDORA_EXPRESS_DIR}/lib/*
  mv ${ES_DIST_DIR}/${PANDORA_FOLDER_NAME} ${PANDORA_EXPRESS_DIR}/lib

  if [[ ! -d ${PANDORA_ROOT_DIR}/log ]]; then
    mkdir -p ${PANDORA_ROOT_DIR}/log
  fi
}

cpFrontendToRelease() {
  rm -rf ${PANDORA_ROOT_DIR}/webapp
  mkdir -p ${PANDORA_ROOT_DIR}/webapp
  cp -r ${project}/webapp/build/* ${PANDORA_ROOT_DIR}/webapp/
}
# 生成自检文件列表
genSelfCheckManifest() {
  echo -e "\ngenerate self-checking manifest\n"
  subdirs="lib/pandora/bin lib/pandora/lib lib/pandora/modules lib/pandora/webapp lib/pandora/plugins"
  rm -f $PANDORA_EXPRESS_DIR/lib/pandora/pandora_manifest
  for dir in $subdirs; do
    if [ ! -d $PANDORA_EXPRESS_DIR/$dir ]; then
      continue
    fi
    genSelfCheckByDir $PANDORA_EXPRESS_DIR/$dir "pandora-express/lib/pandora/" ""
  done
  openssl dgst -sign $PROJECT_ROOT/rsa_private.key -sha1 -out $PROJECT_ROOT/pandora_manifest.sign $PANDORA_EXPRESS_DIR/lib/pandora/pandora_manifest
  if [ -n "$IS_DARWIN" ]; then
    manifestSign=$(base64 $PROJECT_ROOT/pandora_manifest.sign)
  else
    manifestSign=$(base64 --wrap=0 $PROJECT_ROOT/pandora_manifest.sign)
  fi
  echo $manifestSign >$PANDORA_EXPRESS_DIR/lib/pandora/pandora_manifest_signature
  rm -f $PROJECT_ROOT/pandora_manifest.sign
}

genSelfCheckByDir() {
  spliter=$2
  prefix=$3
  for file in $1/*; do
    # 前端配置文件不能校验
    if [ "${file:0-19}" = "/static/config.json" ]; then
      continue
    fi
    # pandora_manifest 文件本身不能校验
    if [ "${file:0-22}" = "/conf/pandora_manifest" ]; then
      continue
    fi
    # es配置文件不能校验
    if [ "${file:0-23}" = "/conf/elasticsearch.yml" ]; then
      continue
    fi
    # 文件名中带空格的不校验
    if [[ "${file}" =~ " " ]]; then
      continue
    fi
    if test -f "${file}"; then
      fileToken=$(md5sum "${file}" | awk '{print $2 " " $1}' | awk -F ${spliter} '{print $2}')
      echo ${prefix}${fileToken} >>$PANDORA_EXPRESS_DIR/lib/pandora/pandora_manifest
      continue
    fi
    if test -d "${file}"; then
      genSelfCheckByDir "${file}" ${spliter} ${prefix}
    fi
  done
}

packageRelease(){
  cd ${PANDORA_EXPRESS_DIR}/lib
  tar -zcvf "pandora-phoenix-${VERSION}.tar.gz" "./pandora"
}

pushDockerImage2Registry(){
  cd $PROJECT_ROOT
  docker build --rm -t "aslan-spock-register.qiniu.io/pandora/pandora2.0-express:${VERSION}" -f distribution/docker/phoenix/Dockerfile "distribution"
  docker push "aslan-spock-register.qiniu.io/pandora/pandora2.0-express:${VERSION}"
}

package(){
  renameBuildResult

  mvPhoenixToRelease

  cpFrontendToRelease

  genSelfCheckManifest

  packageRelease

  pushDockerImage2Registry
}

package
