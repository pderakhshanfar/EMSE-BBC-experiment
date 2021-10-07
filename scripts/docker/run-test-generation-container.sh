# After building the the image, we run the container

COMMAND=$1

${COMMAND} stop test-generation-container
${COMMAND} rm test-generation-container

${COMMAND} run -dit -u ${UID} -v ${PWD}:/experiment --name test-generation-container  \
test-generation-img