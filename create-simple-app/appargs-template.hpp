#ifndef APPARGS_H
#define APPARGS_H

#include <iostream>
#include <string>
#include <vector>


//------------------------------------------------------------------------------
//  T Y P E S
//------------------------------------------------------------------------------
struct appargs_t {

    std::vector<std::string> args; // Arguments that are not options

    appargs_t (int argc, char* argv[]);
    void print_usage_and_exit (std::ostream& out, int exit_code);
};

#endif
