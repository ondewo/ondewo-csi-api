export

# PR BEFORE RELEASE
# 1 - Update Version Number
# 2 - Update RELEASE.md
#
# Fully automated build and deploy process for ondewo-csi-api
# Release Process Steps:
# 1 - Create Release Branch and push
# 2 - Create Release Tag and push
# 3 - GitHub Release

# MUST BE THE SAME AS API in Mayor and Minor Version Number
# example: API 2.9.0 --> Client 2.9.X
ONDEWO_CSI_API_VERSION=2.0.0
ONDEWO_NLU_API_GIT_BRANCH=tags/2.9.0
ONDEWO_S2T_API_GIT_BRANCH=tags/3.2.0
ONDEWO_T2S_API_GIT_BRANCH=tags/4.2.0
ONDEWO_NLU_DIR=ondewo-nlu-api
ONDEWO_S2T_DIR=ondewo-s2t-api
ONDEWO_T2S_DIR=ondewo-t2s-api


# You need to setup an access token at https://github.com/settings/tokens - permissions are important
GITHUB_GH_TOKEN?=ENTER_YOUR_TOKEN_HERE

CURRENT_RELEASE_NOTES=`cat RELEASE.md \
	| sed -n '/Release ONDEWO CSI API ${ONDEWO_CSI_API_VERSION}/,/\*\*/p'`


# Choose repo to release to - Example: "https://github.com/ondewo/ondewo-nlu-client-python"
GH_REPO="https://github.com/ondewo/ondewo-csi-api"

# Utils release docker image environment variables
IMAGE_UTILS_NAME=ondewo-csi-api-utils:${ONDEWO_CSI_API_VERSION}

.DEFAULT_GOAL := help

# First comment after target starting with double ## specifies usage
help:  ## Print usage info about help targets
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

init_submodules:  ## Initialize submodules
	@echo "START initializing submodules ..."
	git submodule update --init --recursive
	@echo "DONE initializing submodules"

checkout_defined_submodule_versions:  ## Update submodule versions
	@echo "START checking out submodules ..."
	git -C ${ONDEWO_T2S_DIR} fetch --all
	git -C ${ONDEWO_T2S_DIR} checkout ${ONDEWO_T2S_API_GIT_BRANCH}
	git -C ${ONDEWO_NLU_DIR} fetch --all
	git -C ${ONDEWO_NLU_DIR} checkout ${ONDEWO_NLU_API_GIT_BRANCH}
	git -C ${ONDEWO_S2T_DIR} fetch --all
	git -C ${ONDEWO_S2T_DIR} checkout ${ONDEWO_S2T_API_GIT_BRANCH}
	if [ -d googleapis ]; then rm -Rf googleapis; fi
	cp -r "${ONDEWO_NLU_DIR}/googleapis" .
	if [ -d ondewo/nlu ]; then rm -Rf ondewo/nlu; fi
	if [ -d ondewo/s2t ]; then rm -Rf ondewo/s2t; fi
	if [ -d ondewo/t2s ]; then rm -Rf ondewo/t2s; fi
	cp -r "${ONDEWO_NLU_DIR}/ondewo/nlu" ondewo
	cp -r "${ONDEWO_T2S_DIR}/ondewo/t2s" ondewo
	cp -r "${ONDEWO_S2T_DIR}/ondewo/s2t" ondewo


	@echo "DONE checking out submodules"

release: create_release_branch create_release_tag build_and_release_to_github_via_docker  ## Automate the entire release process
	@echo "Release Finished"

create_release_branch: ## Create Release Branch and push it to origin
	git checkout -b "release/${ONDEWO_CSI_API_VERSION}"
	git push -u origin "release/${ONDEWO_CSI_API_VERSION}"

create_release_tag: ## Create Release Tag and push it to origin
	git tag -a ${ONDEWO_CSI_API_VERSION} -m "release/${ONDEWO_CSI_API_VERSION}"
	git push origin ${ONDEWO_CSI_API_VERSION}

build: init_submodules checkout_defined_submodule_versions

build_and_release_to_github_via_docker: build build_utils_docker_image release_to_github_via_docker_image  ## Release automation for building and releasing on GitHub via a docker image

login_to_gh: ## Login to Github CLI with Access Token
	echo $(GITHUB_GH_TOKEN) | gh auth login -p ssh --with-token

build_gh_release: ## Generate Github Release with CLI
	gh release create --repo $(GH_REPO) "$(ONDEWO_CSI_API_VERSION)" -n "$(CURRENT_RELEASE_NOTES)" -t "Release ${ONDEWO_CSI_API_VERSION}"

build_utils_docker_image:  ## Build utils docker image
	docker build -f Dockerfile.utils -t ${IMAGE_UTILS_NAME} .

push_to_gh: login_to_gh build_gh_release
	@echo 'Released to Github'

release_to_github_via_docker_image:  ## Release to Github via docker
	docker run --rm \
		-e GITHUB_GH_TOKEN=${GITHUB_GH_TOKEN} \
		${IMAGE_UTILS_NAME} make push_to_gh

ondewo_release: spc clone_devops_accounts run_release_with_devops ## Release with credentials from devops-accounts repo
	@rm -rf ${DEVOPS_ACCOUNT_GIT}

clone_devops_accounts: ## Clones devops-accounts repo
	if [ -d $(DEVOPS_ACCOUNT_GIT) ]; then rm -Rf $(DEVOPS_ACCOUNT_GIT); fi
	git clone git@bitbucket.org:ondewo/${DEVOPS_ACCOUNT_GIT}.git

DEVOPS_ACCOUNT_GIT="ondewo-devops-accounts"
DEVOPS_ACCOUNT_DIR="./${DEVOPS_ACCOUNT_GIT}"

TEST:
	@echo ${GITHUB_GH_TOKEN}
	@echo ${CURRENT_RELEASE_NOTES}

run_release_with_devops:
	$(eval info:= $(shell cat ${DEVOPS_ACCOUNT_DIR}/account_github.env | grep GITHUB_GH & cat ${DEVOPS_ACCOUNT_DIR}/account_pypi.env | grep PYPI_USERNAME & cat ${DEVOPS_ACCOUNT_DIR}/account_pypi.env | grep PYPI_PASSWORD))
	make release $(info)

spc: ## Checks if the Release Branch, Tag and Pypi version already exist
	$(eval filtered_branches:= $(shell git branch --all | grep "release/${ONDEWO_CSI_API_VERSION}"))
	$(eval filtered_tags:= $(shell git tag --list | grep "${ONDEWO_CSI_API_VERSION}"))
	@if test "$(filtered_branches)" != ""; then echo "-- Test 1: Branch exists!!" & exit 1; else echo "-- Test 1: Branch is fine";fi
	@if test "$(filtered_tags)" != ""; then echo "-- Test 2: Tag exists!!" & exit 1; else echo "-- Test 2: Tag is fine";fi