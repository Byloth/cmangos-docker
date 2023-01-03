#!/usr/bin/env bash
#

set -e

function docker-build()
{
    docker build ${@} \
             \
             ${NO_CACHE} \
             ${PULL} \
             \
             --build-arg TIMEZONE="${TIMEZONE}" \
             --build-arg EXPANSION="${EXPANSION}" \
             --build-arg MANGOS_SHA1="${MANGOS_SHA1}" \
             --build-arg DATABASE_SHA1="${DATABASE_SHA1}" \
             --build-arg THREADS="${THREADS}" \
             --build-arg COMMIT_SHA="${COMMIT_SHA}" \
             --build-arg CREATE_DATE="${TIMESTAMP}" \
             --build-arg VERSION="${VERSION_CODE}" \
    \
    . # There's a `dot` on this line!
}

function build-builder()
{
    _docker-build --tag "${IMAGE}/builder:${EXPANSION}" \
                  --target "builder"
}
function build-runner()
{
    _docker-build --tag "${IMAGE}/runner:${EXPANSION}"
}

readonly EXECUTABLE="${0}"
readonly HELP_MSG="
Allows you to build more easily the Docker images
 of CMaNGOS you'll need to run the server propertly.

Usage:
    ${EXECUTABLE} [OPTIONS...]

Options:
    -e | --expansion \"classic\" | \"tbc\" | \"wotlk\"
        Specify the latest game expansion
         that CMaNGOS will support.
        When not specified, the expansion
         is \"tbc\" by default.

    -x | --target \"runner\" | \"builder\" | \"all\"
        Specify the Docker image target to build.
        When not specified, the target
         is \"runner\" by default.

    -i | --image <name>
        Specify the prefix that will be used
         to name the built Docker image.
        When not specified, the prefix
         name is \"cmangos\" by default.

    -z | --timezone <timezone>
        Specify the timezone that will be injected
         as a default into the built Docker image.
        When not specified, the timezone
         is \"Europe/Rome\" by default.

    -t | --threads <number>
        Specify the number of threads that
         will be used during the build process.
        When not specified, the number of
         threads is 2 by default.

    -C | --no-cache
        Force Docker to build the images
         from scratch without using any cache.

    -p | --pull
        Force Docker to pull the latest core
         image from DockerHub before building.
    
    -h | -? | --help
        Displays this help message.
"

while [[ ${#} -gt 0 ]]
do
    case "${1}" in
        -e | --expansion)
            if [[ "${2}" != "classic" ]] && [[ "${2}" != "tbc" ]] && [[ "${2}" != "wotlk" ]]
            then
                echo ""
                echo -e " ERROR!"
                echo -e "  └ Invalid expansion specified: \"${2}\""
                echo ""
                echo " Run \"${EXECUTABLE} --help\" for more information."

                exit 2
            fi

            readonly EXPANSION="${2}"

            shift
            ;;
        -x | --target)
            if [[ "${2}" != "runner" ]] && [[ "${2}" != "builder" ]] && [[ "${2}" != "all" ]]
            then
                echo ""
                echo -e " ERROR!"
                echo -e "  └ Invalid target specified: \"${2}\""
                echo ""
                echo " Run \"${EXECUTABLE} --help\" for more information."

                exit 3
            fi

            readonly TARGET="${2}"

            shift
            ;;
        -i | --image)
            readonly IMAGE="${2}"

            shift
            ;;
        -z | --timezone)
            readonly TIMEZONE="${2}"

            shift
            ;;
        -t | --threads)
            if [[ ! "${2}" =~ ^[0-9]+$ ]]
            then
                echo ""
                echo -e " ERROR!"
                echo -e "  └ Invalid threads number specified: \"${2}\""
                echo ""
                echo " Run \"${EXECUTABLE} --help\" for more information."

                return 4
            fi

            readonly THREADS="${2}"

            shift
            ;;
        -C | --no-cache)
            readonly NO_CACHE="--no-cache"
            ;;
        -p | --pull)
            readonly PULL="--pull"
            ;;
        -h | -? | --help)
            echo -e "${HELP_MSG}"

            exit 0
            ;;
        *)
            echo ""
            echo -e " ERROR!"
            echo -e "  └ Unknown option: \"${1}\""
            echo ""
            echo " Run \"${EXECUTABLE} --help\" for more information."

            exit 1
            ;;
    esac

    shift
done

if [[ -z "${TARGET}" ]]
then
    readonly TARGET="runner"
fi
if [[ -z "${EXPANSION}" ]]
then
    readonly EXPANSION="tbc"
fi
if [[ -z "${IMAGE}" ]]
then
    readonly IMAGE="ghcr.io/byloth/cmangos/tbc"
fi
if [[ -z "${TIMEZONE}" ]]
then
    readonly TIMEZONE="Europe/Rome"
fi

readonly MANGOS_SHA1="b337c14a55502203d5571fd4debf0d888809dd25"
readonly DATABASE_SHA1="db459949c86afd9dea5a31f316986d5d77a9a7c1"

readonly COMMIT_SHA="$(git log -1 --format="%H")"
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly VERSION_CODE="1.0.0-develop+$(date -u +"%Y%m%d%H%M%S")"

if [[ "${TARGET}" == "builder" ]] || [[ "${TARGET}" == "all" ]]
then
    docker-build --tag "${IMAGE}/builder:${EXPANSION}" \
                 --target "builder"
fi
if [[ "${TARGET}" == "runner" ]] || [[ "${TARGET}" == "all" ]]
then
    docker-build --tag "${IMAGE}:${EXPANSION}"
fi
