#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>



//------------------------------------------------------------------------------
//  T Y P E S
//------------------------------------------------------------------------------
struct options_t {
};
typedef struct options_t options_t;



//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
static void print_usage_and_exit (FILE* fd, int exit_code)
{
    fprintf (fd,
             "Usage: %s [OPTIONS]\n"
             "\n"
             "Options:\n"
             "\n"
             "  -h, --help    Print this help message.\n"
             "\n",
             program_invocation_short_name);
    exit (exit_code);
}


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
static void parse_cmdline_arguments (int argc, char* argv[], options_t* opt)
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
            print_usage_and_exit (stdout, 0);
            break;
        default:
            fprintf (stderr, "Use option -h for help.");
            exit (1);
        }
    }

    while (optind < argc) {
        // handle arguments that aren't options
        ++optind;
    }
}


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
int main (int argc, char* argv[])
{
    options_t opt;
    parse_cmdline_arguments (argc, argv, &opt);

    return 0;
}
