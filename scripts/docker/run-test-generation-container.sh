# After building the the image, we run the container

COMMAND=$1

${COMMAND} stop test-generation-container
${COMMAND} rm test-generation-container

${COMMAND} run -dit --name test-generation-container  \
--mount type=bind,source="$(pwd)/subjects",target=/experiment/subjects \
--mount type=bind,source="$(pwd)/defects4j",target=/experiment/defects4j \
--mount type=bind,source="$(pwd)/results",target=/experiment/results \
--mount type=bind,source="$(pwd)/scripts",target=/experiment/scripts \
--mount type=bind,source="$(pwd)/SEED",target=/experiment/SEED \
--mount type=bind,source="$(pwd)/tools",target=/experiment/tools \
--mount type=bind,source="$(pwd)/configurations",target=/experiment/configurations \
test-generation-img