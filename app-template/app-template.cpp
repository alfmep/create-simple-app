#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdint>
#include <cerrno>
#include <unistd.h>
#include <getopt.h>

using std::cin;
using std::cout;
using std::cerr;
using std::endl;
using std::string;


//------------------------------------------------------------------------------
//  T Y P E S
//------------------------------------------------------------------------------
struct options_t {
    std::vector<std::string> args; // Arguments that are not options

    options_t (int argc, char* argv[]);
    void print_usage_and_exit (std::ostream& out, int exit_code);
};


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
void options_t::print_usage_and_exit (std::ostream& out, int exit_code)
{
    out << std::endl;
    out << "Usage: " << program_invocation_short_name << " [OPTIONS]" << std::endl;
    out << std::endl;
    out << "Options:" << std::endl;
    out << std::endl;
    out << "  -h, --help    Print this help message." << std::endl;
    out << std::endl;

    exit (exit_code);
}


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
options_t::options_t (int argc, char* argv[])
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

    // Collect all arguments that are not options
    while (optind < argc)
        args.emplace_back (argv[optind++]);
}


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
int main (int argc, char* argv[])
{
    options_t opt (argc, argv);

    return 0;
}
