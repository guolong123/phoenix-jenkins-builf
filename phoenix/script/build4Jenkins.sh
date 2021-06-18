PROJECT_ROOT="$(pwd)"

export project=${PROJECT_ROOT}
ES_FOLDER_NAME=elasticsearch-6.8.0-SNAPSHOT
ES_DIST_DIR=${project}/distribution/archives/zip/build/distributions


buildPhoenix() {

  cd ${project}

  echo -e "\nBuilding pandora\n"
  echo -e "./gradlew dependencies on "${project}
  echo -e "./gradlew assemble --parallel on "${project}

  ./gradlew assemble --parallel

  ## rename folder and jar name
  cd ${ES_DIST_DIR}
  rm -rf elasticsearch-6.8.0-SNAPSHOT
  unzip elasticsearch-6.8.0-SNAPSHOT.zip
}

buildPhoenix
