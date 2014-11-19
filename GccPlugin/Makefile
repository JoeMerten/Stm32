
PLUGINS_INC_DIR := $(shell g++ -print-file-name=plugin)/include

CFLAGS += -funsigned-char
CXXFLAGS += -std=gnu++1y
CFLAGS += -fmessage-length=0
CFLAGS += -Wall
CFLAGS += -Wextra
#CFLAGS += -Wundef # geht nicht wg. diverser gcc plugin header
#CXXFLAGS += -Weffc++ # geht nicht wg. diverser gcc plugin header
CFLAGS += -Wno-literal-suffix # erforderlich für elfos.h und defaults.h
CXXFLAGS += -Woverloaded-virtual

all:
	g++ -I$(PLUGINS_INC_DIR) $(CFLAGS) $(CXXFLAGS) -fPIC -shared Src/Main.cxx -o Out/JoeGccPlugin.so
	g++ -S -fplugin=Out/JoeGccPlugin.so -fplugin-arg-JoeGccPlugin-key1=value1 Src/Test.cxx