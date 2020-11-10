# After building the the image, we run the container
docker run -dit --name test-generation-container  \
--mount type=bind,source="$(pwd)/subjects",target=/experiment/subjects \
--mount type=bind,source="$(pwd)/results",target=/experiment/results \
test-generation-img