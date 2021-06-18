PV_DIR=$1
project='..'
echo -e "\nBuilding fronted\n"
echo -e "\n link PV: ${LINK_PANDORA_VISUALIZATION}\n"
echo -e "\n link SearchEditor: ${LINK_SEARCH_EDITOR}\n"

echo -e "\nBuilding SearchEditor\n"

cd ${project}/search-editor
yarn install
yarn build
yarn link

cd ${project}/webapp

yarn install

CRT_DIR="$PWD"

echo -e "\nStarting link PV to phoenix\n"
echo -e "\n PV DIR: ${PV_DIR}"

rm -rf node_modules/@qn-pandora/app-renderer/*
rm -rf node_modules/@qn-pandora/app-sdk/*
rm -rf node_modules/@qn-pandora/pandora-component/*
rm -rf node_modules/@qn-pandora/pandora-app-component/*
rm -rf node_modules/@qn-pandora/pandora-visualization/*
rm -rf node_modules/@qn-pandora/visualization-sdk/*
rm -rf node_modules/@qn-pandora/pandora-component-icons/*

cp -rf ${PV_DIR}/node_modules/@qn-pandora/app-renderer/* node_modules/@qn-pandora/app-renderer/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/app-sdk/* node_modules/@qn-pandora/app-sdk/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/pandora-component/* node_modules/@qn-pandora/pandora-component/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/pandora-app-component/* node_modules/@qn-pandora/pandora-app-component/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/pandora-visualization/* node_modules/@qn-pandora/pandora-visualization/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/visualization-sdk/* node_modules/@qn-pandora/visualization-sdk/
cp -rf ${PV_DIR}/node_modules/@qn-pandora/pandora-component-icons/* node_modules/@qn-pandora/pandora-component-icons/


echo -e '\nStarting link SearchEditor to phoenix\n'

cd node_modules/@qn-pandora/pandora-app-component
echo "now dir: ${PWD}"
yarn link @qn-pandora/search-editor
cd $CRT_DIR


webapp_args="-c $DEPLOY -p $PUBLIC_URL -b $BACKEND_URL"
if [[ "$ENABLE_MICRO_FE" == "true" ]]; then
  webapp_args="$webapp_args -e"
fi

echo -e '\nStarting build webapp \n'
yarn build $webapp_args

yarn unlink @qn-pandora/search-editor
