#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdint>
#include <cerrno>
#include <unistd.h>
#include <getopt.h>

#include "APPARGS_H"


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
void appargs_t::print_usage_and_exit (std::ostream& out, int exit_code)
{
    out << std::endl
        << "Usage: " << program_invocation_short_name << " [OPTIONS]" << std::endl
        << std::endl
        << "  -h, --help    Print this help message." << std::endl
        << std::endl;

        exit (exit_code);
}


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
appargs_t::appargs_t (int argc, char* argv[])
{
    static struct option long_options[] = {
        { "help", no_argument, 0, 'h'},
        { 0, 0, 0, 0}
    };
    static const char* arg_format = "h";

    while (1) {
        int c = getopt_long (argc, argv, arg_format, long_options, NULL);
        if (c == -1)
            break;
        switch (c) {
        case 'h':
            print_usage_and_exit (std::cout, 0);
            break;
        default:
            std::cerr << "Use option -h for help." << std::endl;
            exit (1);
        }
    }

    // Collect all arguments thar are not options
    while (optind < argc)
        args.emplace_back (argv[optind++]);
}
