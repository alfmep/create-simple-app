#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdint>
#include <cerrno>

#include "APPARGS_H"

using std::cin;
using std::cout;
using std::cerr;
using std::endl;
using std::string;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
int main (int argc, char* argv[])
{
    appargs_t opt (argc, argv);

    return 0;
}
