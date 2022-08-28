IMAGES_DIR=images
CP_OPTS=-n -l
ROUGE_STYLE=monokai_sublime

STYLESHEET_FILE=golo.css
STYLESHEET_DIR=$(BASE_DIR)/docs/stylesheets

AD_OPTS_HTML5_COMMON=\
--backend=html5 \
-a stylesheet=$(STYLESHEET_FILE) -a stylesdir=$(STYLESHEET_DIR) \
-a imagesdir=$(IMAGES_DIR)

AD_OPTS_HTML5_ROUGE=\
$(AD_OPTS_HTML5_COMMON) \
-r asciidoctor-diagram \
-a source-highlighter=rouge \
-a rouge-style=$(ROUGE_STYLE)
