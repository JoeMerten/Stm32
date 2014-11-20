
PROJECT_NAME := JoeGccPlugin

SRCS := Src/Main.cxx

TEST_SRCS := Src/Test.cxx 

########################################################################################################################
# Projektpfade
########################################################################################################################

# Default Build-Verzeichnis
TOPBUILDDIR ?= Out

BUILDDIR    ?= $(TOPBUILDDIR)
EXENOEXT    ?= $(BUILDDIR)/$(PROJECT_NAME)
EXELIB      ?= $(EXENOEXT).so

PLUGINS_INC_DIR := $(shell g++ -print-file-name=plugin)/include

########################################################################################################################
# Compilerflags
########################################################################################################################

CFLAGS += -funsigned-char
CXXFLAGS += -std=gnu++1y
CFLAGS += -fmessage-length=0
CFLAGS += -Wall
CFLAGS += -Wextra
#CFLAGS += -Wundef # geht nicht wg. diverser gcc plugin header
#CXXFLAGS += -Weffc++ # geht nicht wg. diverser gcc plugin header
CFLAGS += -Wno-literal-suffix # erforderlich für elfos.h und defaults.h
CXXFLAGS += -Woverloaded-virtual

########################################################################################################################
# Targets
########################################################################################################################

all:
	g++ -I$(PLUGINS_INC_DIR) $(CFLAGS) $(CXXFLAGS) -fPIC -shared $(SRCS) -o $(EXELIB)
	g++ $(CFLAGS) $(CXXFLAGS) -S -fplugin=$(EXELIB) -fplugin-arg-$(PROJECT_NAME)-key1=value1 $(TEST_SRCS)

clean:
	rm -rf $(TOPBUILDDIR)/*
	
cleanall:
	rm -rf $(TOPBUILDDIR)/*
	