#!/bin/bash
TEMPLATE_ID="$1"
TEMPLATE_ARGS="${2:-}"

set -e

shopt -s dotglob

if [ -z "${TEMPLATE_ARGS}" ]; then
    TEMPLATE_ARGS="{}"
fi

if ! jq -e 'type == "object" and all(to_entries[]; (.value | type) == "string")' <<<"${TEMPLATE_ARGS}" >/dev/null; then
    echo "Template arguments must be a JSON object with string values"
    exit 1
fi

SRC_DIR="/tmp/${TEMPLATE_ID}"
cp -R "src/${TEMPLATE_ID}" "${SRC_DIR}"

pushd "${SRC_DIR}"

# Configure templates only if `devcontainer-template.json` contains the `options` property.
OPTION_PROPERTY=( $(jq -r '.options' devcontainer-template.json) )

if [ "${OPTION_PROPERTY}" != "" ] && [ "${OPTION_PROPERTY}" != "null" ] ; then  
    OPTIONS=( $(jq -r '.options | keys[]' devcontainer-template.json) )

    if [ "${OPTIONS[0]}" != "" ] && [ "${OPTIONS[0]}" != "null" ] ; then
        echo "(!) Configuring template options for '${TEMPLATE_ID}'"
        for OPTION in "${OPTIONS[@]}"
        do
            OPTION_KEY="\${templateOption:$OPTION}"
            if jq -e --arg option "${OPTION}" 'has($option)' <<<"${TEMPLATE_ARGS}" >/dev/null; then
                OPTION_VALUE=$(jq -r --arg option "${OPTION}" '.[$option]' <<<"${TEMPLATE_ARGS}")
            else
                OPTION_VALUE=$(jq -r --arg option "${OPTION}" '.options[$option].default' devcontainer-template.json)
            fi

            if [ "${OPTION_VALUE}" = "" ] || [ "${OPTION_VALUE}" = "null" ] ; then
                echo "Template '${TEMPLATE_ID}' is missing a default value for option '${OPTION}'"
                exit 1
            fi

            echo "(!) Replacing '${OPTION_KEY}' with '${OPTION_VALUE}'"
            OPTION_VALUE_ESCAPED=$(sed -e 's/[]\/$*.^[]/\\&/g' <<<"${OPTION_VALUE}")
            find ./ -type f -print0 | xargs -0 sed -i.template-option-backup "s/${OPTION_KEY}/${OPTION_VALUE_ESCAPED}/g"
            find ./ -type f -name '*.template-option-backup' -delete
        done
    fi
fi

popd

TEST_DIR="test/${TEMPLATE_ID}"
if [ -d "${TEST_DIR}" ] ; then
    echo "(*) Copying test folder"
    DEST_DIR="${SRC_DIR}/test-project"
    mkdir -p ${DEST_DIR}
    cp -Rp ${TEST_DIR}/* ${DEST_DIR}
    cp -Rp test/test-utils/* ${DEST_DIR}
fi

export DOCKER_BUILDKIT=1
echo "(*) Installing @devcontainer/cli"
npm install -g @devcontainers/cli

echo "Building Dev Container"
ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer up --id-label ${ID_LABEL} --workspace-folder "${SRC_DIR}"
