COMMAND=$1

${COMMAND} stop test-generation-container
${COMMAND} rm test-generation-container

${COMMAND} run -dit -u ${UID} --name test-generation-container  \
--mount type=bind,source="$(pwd)/subjects",target=/experiment/subjects \
--mount type=bind,source="$(pwd)/defects4j",target=/experiment/defects4j \
--mount type=bind,source="$(pwd)/results",target=/experiment/results \
--mount type=bind,source="$(pwd)/scripts",target=/experiment/scripts \
--mount type=bind,source="$(pwd)/results/SEED",target=/experiment/SEED \
--mount type=bind,source="$(pwd)/tools",target=/experiment/tools \
--mount type=bind,source="$(pwd)/configurations",target=/experiment/configurations \
--mount type=bind,source="$(pwd)/console-logs",target=/experiment/console-logs \
--mount type=bind,source="$(pwd)/libs",target=/experiment/libs \
--mount type=bind,source="$(pwd)/data",target=/experiment/data \
--mount type=bind,source="$(pwd)/logs",target=/experiment/logs \
--mount type=bind,source="$(pwd)/tests-without-trycatch",target=/experiment/tests-without-trycatch \
test-generation-img

