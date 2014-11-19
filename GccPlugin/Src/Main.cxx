/*
 * http://www.codesynthesis.com/~boris/blog/2010/05/03/parsing-cxx-with-gcc-plugin-part-1/
 * https://gcc.gnu.org/onlinedocs/gccint/Plugins.html
 *
 * Prerequisites:
 * - gcc >= 4.8
 * - sudo apt-get install gcc-4.8-plugin-dev
 */

#define _UNUSED_              __attribute__((unused))
#define _UNUSED_FUNCTION_     __attribute__((unused))

// GCC header includes to get the parse tree declarations.
// The order is important and doesn't follow any kind of logic.
#include <stdlib.h>
#include <gmp.h>
#include <cstdlib> // Include before GCC poisons some declarations.

#include "gcc-plugin.h"

#include "config.h"
#include "system.h"
#include "coretypes.h"
#include "tree.h"
#include "intl.h"

#include "tm.h"

#include "cp/cp-tree.h"
#include "diagnostic.h"
#include "c-family/c-common.h"
#include "c-family/c-pragma.h"

#include <iostream>

using namespace std;

int plugin_is_GPL_compatible;

extern "C" _UNUSED_ void gateCallback(_UNUSED_ void* gccData, _UNUSED_ void* userData) {
    // If there were errors during compilation, let GCC handle the exit.
    if (errorcount || sorrycount)
        return;

    int r = 0;

    // Process AST. Issue diagnostics and set r to 1 in case of an error.
    cerr << "processing " << main_input_filename << endl;

    exit(r);
}

extern "C" _UNUSED_ void passExecCallback(_UNUSED_ void* gccData, _UNUSED_ void* userData) {
    cerr << "processing " << main_input_filename << endl;
}


extern "C" int plugin_init(plugin_name_args* info, plugin_gcc_version* ver) {
    int r = 0;

    cerr << "starting " << info->base_name << endl;

    cerr << "gcc version: " << endl;
    cerr << "  basever  = " << ver->basever                 << endl;
    cerr << "  datestamp= " << ver->datestamp               << endl;
    cerr << "  devphase = " << ver->devphase                << endl;
    cerr << "  revision = " << ver->revision                << endl;
    cerr << "  cfg_args = " << ver->configuration_arguments << endl;


    // Parse options if any.
    cerr << "plugin args:" << endl;
    const plugin_argument* arg = info->argv;
    for (int i = 0; i < info->argc; i++) {
        cerr << "  " << i+1 << ": " << arg->key << " = " << arg->value << endl;
    }

    // Disable assembly output
    asm_file_name = HOST_BIT_BUCKET;

    {
        // Informationen zu meinem Plugin bekannt geben
        // https://gcc.gnu.org/onlinedocs/gccint/Plugins-description.html#Plugins-description
        plugin_info myInfo;
        myInfo.version = "Joe's 1st GCC plugin";
        myInfo.help = "TODO: Some help needed";
        register_callback(info->base_name, PLUGIN_INFO, nullptr, &myInfo);
    }


    // Register callbacks
    register_callback(info->base_name, PLUGIN_OVERRIDE_GATE, &gateCallback, nullptr);
    //register_callback(info->base_name, PLUGIN_PASS_EXECUTION, &passExecCallback, nullptr);
    return r;
}
