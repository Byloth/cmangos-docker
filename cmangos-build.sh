#!/usr/bin/env bash
#

set -e

readonly BASE_DIR="$(realpath "$(dirname "${0}")")"
source "${BASE_DIR}/.env"

function docker-build()
{
    docker buildx build ${@} \
             \
             ${NO_CACHE} \
             ${PULL} \
             \
             --build-arg TIMEZONE="${TIMEZONE}" \
             --build-arg EXPANSION="${EXPANSION}" \
             --build-arg THREADS="${THREADS}" \
             --build-arg COMMIT_SHA="${COMMIT_SHA}" \
             --build-arg CREATE_DATE="${TIMESTAMP}" \
             --build-arg VERSION="${VERSION_CODE}" \
    \
    . # There's a `dot` on this line!
}

readonly EXECUTABLE="${0}"
readonly HELP_MSG="
Allows you to build more easily the Docker images
 of CMaNGOS you'll need to run the server properly.

Usage:
    ${EXECUTABLE} [OPTIONS...]

Options:
    -x | --target \"runner\" | \"builder\" | \"all\"
        Specify the Docker image target to build.
        When not specified, the target
         is \"runner\" by default.

    -e | --expansion \"classic\" | \"tbc\" | \"wotlk\"
        Specify the latest game expansion
         that CMaNGOS will support.
        When not specified, the expansion
         is \"${WOW_VERSION}\" by default.

    -i | --image <name>
        Specify the repository that will be
         used to name the built Docker image.
        When not specified, the prefix
         name is \"byloth/cmangos-${WOW_VERSION}\" by default.

    -v | --version <version>
        Specify the tag that will be used
         to name the built Docker image.
        When not specified, the tag
         is \"develop\" by default.

    -z | --timezone <timezone>
        Specify the timezone that will be injected
         as a default into the built Docker image.
        When not specified, the timezone
         is \"${WOW_TIMEZONE}\" by default.

    -t | --threads <number>
        Specify the number of threads that
         will be used during the build process.
        When not specified, the number of
         threads is 4 by default.

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
        -i | --image)
            readonly IMAGE="${2}"

            shift
            ;;
        -v | --version)
            readonly VERSION="${2}"

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
            NO_CACHE="--no-cache"
            ;;
        -p | --pull)
            PULL="--pull"
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
    readonly EXPANSION="${WOW_VERSION}"
fi
if [[ -z "${IMAGE}" ]]
then
    readonly IMAGE="byloth/cmangos-${EXPANSION}"
fi
if [[ -z "${VERSION}" ]]
then
    readonly VERSION="develop"
fi
if [[ -z "${TIMEZONE}" ]]
then
    readonly TIMEZONE="${WOW_TIMEZONE}"
fi
if [[ -z "${THREADS}" ]]
then
    readonly THREADS="4"
fi

readonly COMMIT_SHA="$(git log -1 --format="%H")"
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly VERSION_CODE="1.0.0-develop+$(date -u +"%Y%m%d%H%M%S")"

if [[ "${TARGET}" == "builder" ]] || [[ "${TARGET}" == "all" ]]
then
    docker-build --tag "${IMAGE}/builder:${VERSION}" \
                 --target "builder"

    unset NO_CACHE
    unset PULL
fi
if [[ "${TARGET}" == "runner" ]] || [[ "${TARGET}" == "all" ]]
then
    docker-build --tag "${IMAGE}:${VERSION}"
fi
