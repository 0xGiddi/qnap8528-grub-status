###############################################################################
# Makefile for building GRUB with the custom qnap8528led module.
#
# Usage:
#   make [GRUB_VER=2.XX] [target]
#
# Targets:
#   all   - Prepare GRUB source, patch Makefile.core.def to include the
#           custom module, run autogen/configure for x86_64 EFI, build GRUB
#           (with the custom module), and copy the generated module (.mod)
#           to the project root.
#   clean - Remove GRUB build artifacts.
#
# Custom module configuration inserted into Makefile.core.def:
#
#   module = {
#     name = qnap8528led;
#     common = qnap8528led.c;
#   };
###############################################################################

# Define ANSI color codes if the terminal supports them.
ANSI_COLORS := $(shell tput colors 2>/dev/null || echo 0)
ifeq ($(ANSI_COLORS),0)
  INFO_COLOR =
  ERROR_COLOR =
  RESET_COLOR =
else
  INFO_COLOR = \033[32m
  ERROR_COLOR = \033[31m
  RESET_COLOR = \033[0m
endif

GRUB_VER ?= $(shell grub-install --version 2>/dev/null | sed -n 's/.* \(2\.[0-9][0-9]\).*/\1/p')
CHECK_VERSION := $(shell echo $(GRUB_VER) | grep -E "^2\.[0-9][0-9]$$")
ifeq ($(CHECK_VERSION),)
  $(error "GRUB_VER must be in format 2.XX (only GRUB 2 is supported), got: '$(GRUB_VER)'")
endif
#----------------------------------------------------------------------
# Choose GRUB source directory.
# If a directory "grub-2.XX" exists at the project root, use it;
# otherwise, default to the git submodule in "./grub".
#----------------------------------------------------------------------
GRUB_VERSION_DIR := grub2-$(GRUB_VER)
ifneq ($(wildcard $(GRUB_VERSION_DIR)),)
  GRUB_DIR := $(GRUB_VERSION_DIR)
  $(info $(INFO_COLOR)[INFO] Using local GRUB source directory: $(GRUB_DIR)$(RESET_COLOR))
else
  GRUB_DIR := grub
endif
# GRUB core directory (where we integrate our module)
GRUB_CORE_DIR := $(GRUB_DIR)/grub-core
#----------------------------------------------------------------------
# Module settings.
#----------------------------------------------------------------------
MODULE_SRC := qnap8528led.c
MODULE_NAME := qnap8528led
MODULE_MOD := $(GRUB_CORE_DIR)/$(MODULE_NAME).mod
#----------------------------------------------------------------------
# GRUB configuration options for x86_64 EFI platforms.
#----------------------------------------------------------------------
CONFIGURE_OPTS := --target=x86_64 --with-platform=efi
#----------------------------------------------------------------------
# Phony targets.
#----------------------------------------------------------------------
.PHONY: all checkout patch build copy-module clean
#----------------------------------------------------------------------
# all: Build GRUB (with custom module) and copy the generated module (.mod file)
# into the project root.
#----------------------------------------------------------------------
all: copy-module
	@echo "$(INFO_COLOR)Build complete. New module $(MODULE_NAME).mod has been copied to the project root.$(RESET_COLOR)"
#----------------------------------------------------------------------
# checkout: Prepare the GRUB source.
#
# If using the git submodule ("grub"), checkout the correct tag.
# If using a local source directory (grub-2.XX), assume it is already correct.
#----------------------------------------------------------------------
checkout:
	@if [ "$(GRUB_DIR)" = "grub" ]; then \
		echo "$(INFO_COLOR)Using GRUB git submodule. Checking out tag: grub-$(GRUB_VER)...$(RESET_COLOR)"; \
		cd $(GRUB_DIR) && git fetch --all && git checkout -f grub-$(GRUB_VER); \
	else \
		echo "$(INFO_COLOR)Using local GRUB source directory ($(GRUB_DIR)). Skipping git checkout.$(RESET_COLOR)"; \
	fi
#----------------------------------------------------------------------
# patch: Integrate the custom module into GRUB's build system.
#
# 1. Copy qnap8528led.c into the GRUB core directory.
# 2. Update the file Makefile.core.def (in GRUB_CORE_DIR) to include the custom
#    module configuration block:
#
#    module = {
#      name = qnap8528led;
#      common = qnap8528led.c;
#    };
#
# If the module block already exists, no duplicate will be inserted.
#----------------------------------------------------------------------
patch: checkout
	@echo "$(INFO_COLOR)Copying $(MODULE_SRC) into $(GRUB_CORE_DIR)...$(RESET_COLOR)"
	@cp $(MODULE_SRC) $(GRUB_CORE_DIR)
	@echo "$(INFO_COLOR)Patching $(GRUB_CORE_DIR)/Makefile.core.def to include custom module configuration...$(RESET_COLOR)"
	@if [ ! -f $(GRUB_CORE_DIR)/Makefile.core.def ]; then \
		echo "$(ERROR_COLOR)Error: $(GRUB_CORE_DIR)/Makefile.core.def not found.$(RESET_COLOR)"; \
		exit 1; \
	fi
	@if ! grep -q -E "name[[:space:]]*=[[:space:]]*$(MODULE_NAME)" $(GRUB_CORE_DIR)/Makefile.core.def; then \
		echo "" >> $(GRUB_CORE_DIR)/Makefile.core.def; \
		echo "module = {" >> $(GRUB_CORE_DIR)/Makefile.core.def; \
		echo " name = $(MODULE_NAME);" >> $(GRUB_CORE_DIR)/Makefile.core.def; \
		echo " common = $(MODULE_SRC);" >> $(GRUB_CORE_DIR)/Makefile.core.def; \
		echo "};" >> $(GRUB_CORE_DIR)/Makefile.core.def; \
		echo "$(INFO_COLOR)Custom module configuration appended to Makefile.core.def.$(RESET_COLOR)"; \
	else \
		echo "$(INFO_COLOR)Custom module configuration already present in Makefile.core.def.$(RESET_COLOR)"; \
	fi
#----------------------------------------------------------------------
# build: Run autogen, configure, and build GRUB (with the custom module).
#----------------------------------------------------------------------
build: patch
	@if [ "$(GRUB_DIR)" = "grub" ]; then \
		echo "$(INFO_COLOR)Bootstrapping...$(RESET_COLOR)"; \
		cd $(GRUB_DIR) && ./bootstrap; \
	fi
	@echo "$(INFO_COLOR)Running autogen...$(RESET_COLOR)"
	@cd $(GRUB_DIR) && ./autogen.sh
	@echo "$(INFO_COLOR)Configuring GRUB for x86_64 EFI...$(RESET_COLOR)"
	@cd $(GRUB_DIR) && ./configure $(CONFIGURE_OPTS)
	@echo "$(INFO_COLOR)Building GRUB and module...$(RESET_COLOR)"
	@cd $(GRUB_DIR) && make
#----------------------------------------------------------------------
# copy-module: After building, copy the generated module (.mod file) to the project root.
#----------------------------------------------------------------------
copy-module: build
	@echo "$(INFO_COLOR)Copying the compiled module to the project root...$(RESET_COLOR)"
	@if [ -f $(MODULE_MOD) ]; then \
		cp $(MODULE_MOD) ./$(MODULE_NAME).mod; \
		echo "$(INFO_COLOR)Module copied as $(MODULE_NAME).mod.$(RESET_COLOR)"; \
	else \
		echo "$(ERROR_COLOR)Error: Module file $(MODULE_MOD) not found!$(RESET_COLOR)"; \
		exit 1; \
	fi
#----------------------------------------------------------------------
# clean: Clean GRUB build artifacts and remove generated module object files.
#----------------------------------------------------------------------
clean:
	@echo "$(INFO_COLOR)Cleaning GRUB build artifacts...$(RESET_COLOR)"
	-@cd $(GRUB_DIR) && make clean || true
	-@rm -f $(GRUB_CORE_DIR)/$(MODULE_NAME).o $(GRUB_CORE_DIR)/$(MODULE_NAME).mod
	@echo "$(INFO_COLOR)Clean complete.$(RESET_COLOR)"
