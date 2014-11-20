/***********************************************************************************************************************
  Joe's erster kleiner Test mit GCC Plugins
------------------------------------------------------------------------------------------------------------------------
 Prerequisites:
 - gcc >= 4.8
 - sudo apt-get install gcc-4.8-plugin-dev

 Siehe auch:
 - https://gcc.gnu.org/onlinedocs/gccint/Plugins.html
 - http://www.codesynthesis.com/~boris/blog/2010/05/03/parsing-cxx-with-gcc-plugin-part-1/
***********************************************************************************************************************/

#define _UNUSED_              __attribute__((unused))
#define _UNUSED_FUNCTION_     __attribute__((unused))


/***********************************************************************************************************************
  GCC header includes to get the parse tree declarations.
  The order is important and doesn't follow any kind of logic.
***********************************************************************************************************************/
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
#include "plugin-version.h"


#include <set>
#include <iostream>
#include <cstring>

using namespace std;


/***********************************************************************************************************************
  Erforderliche Variable, sonst wird mein Plugin abgelehnt
***********************************************************************************************************************/
int plugin_is_GPL_compatible;


/***********************************************************************************************************************
  Dump GCC Version-Strukt
***********************************************************************************************************************/
void dumpVersion(const char* label, const plugin_gcc_version& ver) {
    cerr << label << ": " << endl;
    cerr << "  basever  = " << ver.basever                 << endl;
    cerr << "  datestamp= " << ver.datestamp               << endl;
    cerr << "  devphase = " << ver.devphase                << endl;
    cerr << "  revision = " << ver.revision                << endl;
    cerr << "  cfg_args = " << ver.configuration_arguments << endl;
}



/***********************************************************************************************************************
  Etwas Code von hier: http://www.codesynthesis.com/~boris/data/gcc-plugin/plugin-2.cxx
***********************************************************************************************************************/
struct decl_comparator {
    bool operator()(tree x, tree y) const {
        location_t xl(DECL_SOURCE_LOCATION(x));
        location_t yl(DECL_SOURCE_LOCATION(y));

        return xl < yl;
    }
};

typedef std::multiset<tree, decl_comparator> decl_set;

void collect(tree ns, decl_set& set) {
    tree decl;
    cp_binding_level* level(NAMESPACE_LEVEL(ns));

    // Collect declarations
    for (decl = level->names; decl != 0; decl = TREE_CHAIN(decl)) {
        if (DECL_IS_BUILTIN(decl))
            continue;

        set.insert(decl);
    }

    // Traverse namespaces
    for (decl = level->namespaces; decl != 0; decl = TREE_CHAIN(decl)) {
        if (DECL_IS_BUILTIN(decl))
            continue;

        collect(decl, set);
    }
}

string decl_namespace(tree decl) {
    string s, tmp;

    for (tree scope(CP_DECL_CONTEXT(decl)); scope != global_namespace; scope = CP_DECL_CONTEXT(scope)) {
        tree id(DECL_NAME(scope));

        tmp = "::";
        tmp += (id != 0 ? IDENTIFIER_POINTER(id) : "<unnamed>");
        tmp += s;
        s.swap(tmp);
    }

    return s;
}

void print_decl(tree decl) {
    int tc(TREE_CODE(decl));
    tree id(DECL_NAME(decl));
    const char* name(id ? IDENTIFIER_POINTER(id) : "<unnamed>");

    cerr << tree_code_name[tc] << " " << decl_namespace(decl) << "::" << name << " at " << DECL_SOURCE_FILE(decl) << ":" << DECL_SOURCE_LINE(decl) << endl;
}

void traverse(tree ns) {
    decl_set set;
    collect(ns, set);

    for (decl_set::iterator i(set.begin()), e(set.end()); i != e; ++i) {
        print_decl(*i);
    }
}


/***********************************************************************************************************************
  Debug Output
***********************************************************************************************************************/

void dumpDecl(tree decl) {
    print_decl(decl);
}

void dumpTree(tree ns) {
    cp_binding_level* level(NAMESPACE_LEVEL(ns));

    // Collect declarations
    for (tree decl = level->names; decl != 0; decl = TREE_CHAIN(decl))
        if (not DECL_IS_BUILTIN(decl))
            dumpDecl(decl);

    // Traverse namespaces
    for (tree decl = level->namespaces; decl != 0; decl = TREE_CHAIN(decl))
        if (not DECL_IS_BUILTIN(decl)) {
            dumpDecl(decl);
            dumpTree(decl);
        }
}

/***********************************************************************************************************************
  Gate Callback
***********************************************************************************************************************/
extern "C" _UNUSED_ void gateCallback(_UNUSED_ void* gccData, _UNUSED_ void* userData) {
    // If there were errors during compilation, let GCC handle the exit.
    if (errorcount!=0 or sorrycount!=0)
        return;

    int r = 0;

    // Process AST. Issue diagnostics and set r to 1 in case of an error.
    cerr << "processing " << main_input_filename << endl;

    //traverse(global_namespace);
    dumpTree(global_namespace);

    exit(r);
}

/***********************************************************************************************************************
  Pass Exec Callback
***********************************************************************************************************************/
extern "C" _UNUSED_ void passExecCallback(_UNUSED_ void* gccData, _UNUSED_ void* userData) {
    cerr << "processing " << main_input_filename << endl;
}


/***********************************************************************************************************************
  Initialisierug der Plugin
***********************************************************************************************************************/
extern "C" int plugin_init(plugin_name_args* info, plugin_gcc_version* ver) {
    int r = 0;

    cerr << "starting " << info->base_name << endl;

    dumpVersion("Caller Gcc Version", *ver);
    dumpVersion("Plugin Gcc Version", gcc_version);

    // Vorerst nur mit GCC 4.8 getestet
    constexpr char needGccVersion[] = "4.8";
    if (strcmp(ver->basever, needGccVersion) != 0) {
        //cerr << "Error: Need gcc version " << needGccVersion << " but got " << ver->basever << endl;
        error("Need gcc version %s but got %s", needGccVersion, ver->basever);
        return 1;
    }

#if 0
    if (not plugin_default_version_check(ver, &gcc_version)) {
        // Mit diesem default-Check läuft mein Plugin vermutlich nicht mit dem Cross Arm
        error("Version check failed");
        return 1;
    }
#endif


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
