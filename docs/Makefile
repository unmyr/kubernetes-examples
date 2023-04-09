BASE_DIR=..
DOC_ROOT=.

DIST_DIR?=$(BASE_DIR)/dist

include $(DOC_ROOT)/asciidoc.mk

SRC_IMAGES_DIR=$(IMAGES_DIR)
DST_IMAGES_DIR=$(DIST_DIR)/$(IMAGES_DIR)

HTML_LIST=\
mkdir_and_copy \
$(DIST_DIR)/docker_buildpacks.html \
$(DIST_DIR)/docker.html \
$(DIST_DIR)/k8s_kind.html \
$(DIST_DIR)/k8s_kpack.html \
$(DIST_DIR)/k8s_tekton.html \
$(DIST_DIR)/index.html

.PHONY: adoc mkdir_and_copy

adoc: $(HTML_LIST)

mkdir_and_copy:
	mkdir -p $(DIST_DIR)
	-test ! -d $(SRC_IMAGES_DIR) || mkdir -p $(DST_IMAGES_DIR)
	-test ! -d $(SRC_IMAGES_DIR) || cp $(CP_OPTS) $(SRC_IMAGES_DIR)/* $(DST_IMAGES_DIR)/

$(DIST_DIR)/%.html: %.adoc header.adoc
	asciidoctor --trace $(AD_OPTS_HTML5_ROUGE) -o "$@" "$<"
