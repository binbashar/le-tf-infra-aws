.PHONY: help
SHELL                 := /bin/bash
LOCAL_OS_USER_ID      := $(shell id -u)
LOCAL_OS_GROUP_ID     := $(shell id -g)
LOCAL_OS_SSH_DIR      := ~/.ssh
LOCAL_OS_GIT_CONF_DIR := ~/.gitconfig
LOCAL_PWD_DIR         := $(shell pwd)

#
# GIT-RELEASE
#
# pre-req -> https://github.com/pnikosis/semtag
define GIT_SEMTAG_CMD_PREFIX
docker run --rm \
-v ${LOCAL_PWD_DIR}:/data:rw \
-v ${LOCAL_OS_SSH_DIR}:/root/.ssh \
-v ${LOCAL_OS_GIT_CONF_DIR}:/etc/gitconfig \
--entrypoint=/opt/semtag/semtag/semtag \
-it binbash/git-release
endef

GIT_SEMTAG_VER_PATCH := $(shell ${GIT_SEMTAG_CMD_PREFIX} final -s patch -o)
GIT_SEMTAG_VER_MINOR := $(shell ${GIT_SEMTAG_CMD_PREFIX} final -s minor -o)
GIT_SEMTAG_VER_MAJOR := $(shell ${GIT_SEMTAG_CMD_PREFIX} final -s major -o)

help:
	@echo 'Available Commands:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":"}; { if ($$3 == "") { printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2 } else { printf " - \033[36m%-18s\033[0m %s\n", $$2, $$3 }}'

#==============================================================#
# GIT RELEASE                                                  #
#==============================================================#
#===================================#
# GIT RELEASE: CircleCI Jobs cmds   #
#===================================#
release-patch-with-changelog-circleci: ## make changelog-patch && git add && git commit && make release-patch
	make changelog-patch
	git status
	git add CHANGELOG.md
	git commit -m "Updating CHANGELOG.md via make changelog-patch for ${GIT_SEMTAG_VER_PATCH} [ci skip]"
	git push origin master
	make release-patch

release-minor-with-changelog-circleci: ## make changelog-minor && git add && git commit && make release-minor
	make changelog-minor
	git status
	git add CHANGELOG.md
	git commit -m "Updating CHANGELOG.md via make changelog-minor for ${GIT_SEMTAG_VER_MINOR} [ci skip]"
	git push origin master
	make release-minor

release-major-with-changelog-circleci: ## make changelog-major && git add && git commit && make release-major
	make changelog-major
	git status
	git add CHANGELOG.md
	git commit -m "Updating CHANGELOG.md via make changelog-major for ${GIT_SEMTAG_VER_MAJOR} [ci skip]"
	git push origin master
	make release-major

#===================================#
# GIT RELEASE: Localhost cmds       #
#===================================#
#
# VERSION NUMBER: PATCH
#
release-patch: ## releasing patch (eg: 0.0.1 -> 0.0.2) based on semantic tagging script for Git
	# pre-req -> https://github.com/pnikosis/semtag
	${GIT_SEMTAG_CMD_PREFIX} get
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	${GIT_SEMTAG_CMD_PREFIX} final -s patch

release-patch-with-changelog: ## make changelog-patch && git add && git commit && make release-patch
	@if git status | grep 'nothing to commit, working directory clean'; then\
		make changelog-patch;\
		git status;\
		git add CHANGELOG.md;\
		git commit -m "Updating CHANGELOG.md via make changelog-patch for ${GIT_SEMTAG_VER_PATCH} [ci skip]";\
		git push origin master;\
		make release-patch;\
	else\
		echo "===============================================================================================";\
    	echo "Changes in working directory pending to be pushed - please check 'git status' cmd output below ";\
		echo "===============================================================================================";\
    	echo "$$(git status)";\
		echo "===============================================================================================";\
	fi

#
# VERSION NUMBER: MINOR
#
release-minor: ## releasing minor (eg: 0.0.2 -> 0.1.0) based on semantic tagging script for Git
	# pre-req -> https://github.com/pnikosis/semtag
	${GIT_SEMTAG_CMD_PREFIX} get
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	${GIT_SEMTAG_CMD_PREFIX} final -s minor

release-minor-with-changelog: ## make changelog-minor && git add && git commit && make release-minor
	@if git status |grep 'nothing to commit, working directory clean'; then\
		make changelog-minor;\
		git status;\
		git add CHANGELOG.md;\
		git commit -m "Updating CHANGELOG.md via make changelog-minor for ${GIT_SEMTAG_VER_MINOR} [ci skip]";\
		git push origin master;\
		make release-minor;\
	else\
		echo "===============================================================================================";\
    	echo "Changes in working directory pending to be pushed - please check 'git status' cmd output below ";\
		echo "===============================================================================================";\
    	echo "$$(git status)";\
		echo "===============================================================================================";\
	fi

#
# VERSION NUMBER: MAJOR
#
release-major: ## releasing major (eg: 0.1.0 -> 1.0.0) based on semantic tagging script for Git
	# pre-req -> https://github.com/pnikosis/semtag
	${GIT_SEMTAG_CMD_PREFIX} get
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	${GIT_SEMTAG_CMD_PREFIX} final -s major

release-major-with-changelog: ## make changelog-major && git add && git commit && make release-major
	@if git status |grep 'nothing to commit, working directory clean'; then\
		make changelog-major;\
		git status;\
		git add CHANGELOG.md;\
		git commit -m "Updating CHANGELOG.md via make changelog-major for ${GIT_SEMTAG_VER_MAJOR} [ci skip]";\
		git push origin master;\
		make release-major;\
	else\
		echo "===============================================================================================";\
    	echo "Changes in working directory pending to be pushed - please check 'git status' cmd output below ";\
		echo "===============================================================================================";\
    	echo "$$(git status)";\
		echo "===============================================================================================";\
	fi

#==============================================================#
# CHANGELOG                                                    #
#==============================================================#
changelog-init: ## git-chglog (https://github.com/git-chglog/git-chglog) config initialization -> ./.chglog
	@if [ ! -d ./.chglog ]; then\
		docker run --rm -v ${LOCAL_PWD_DIR}:/data -it binbash/git-release --init;\
		sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.chglog;\
	else\
		echo "==============================";\
    	echo "git-chglog already initialized";\
    	echo "==============================";\
    	echo "$$(ls ./.chglog)";\
    	echo "==============================";\
	fi

changelog-patch: ## git-chglog generation for path release
	docker run --rm -v ${LOCAL_PWD_DIR}:/data \
	-it binbash/git-release -o CHANGELOG.md --next-tag ${GIT_SEMTAG_VER_PATCH} \
	| grep -v 'Warning: Permanently added the RSA host key for IP address'
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.chglog
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./CHANGELOG.md

changelog-minor: ## git-chglog generation for minor release
	docker run --rm -v ${LOCAL_PWD_DIR}:/data -it \
	binbash/git-release -o CHANGELOG.md --next-tag ${GIT_SEMTAG_VER_MINOR} \
	| grep -v 'Warning: Permanently added the RSA host key for IP address'
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.chglog
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./CHANGELOG.md

changelog-major: ## git-chglog generation for major release
	docker run --rm -v ${LOCAL_PWD_DIR}:/data -it \
	binbash/git-release -o CHANGELOG.md --next-tag ${GIT_SEMTAG_VER_MAJOR} \
	| grep -v 'Warning: Permanently added the RSA host key for IP address'
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.chglog
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.git
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./CHANGELOG.md