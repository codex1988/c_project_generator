# C_PROJECT_GENERATOR

The C Project Generator is a bash script that automatically creates a logically-structured C project based on a simple configuration file. It's designed to help newcomers to C programming by providing a kind of professional-grade (but actually educational) environment instantly.

---

The project suggest:

- To think about modularity, data communication, and designing a system from basic building blocks from the beginning, not the end
- Logically-organized directory structure
- Proper header and source file separation
- Test (write tests first, to definitely understand what kind of input you'll send to and what kind of output you'll receive from the function)
- Build system (build, run, test, clean via make instantly)
- Version control setup (just init a repo in the project folder, .gitignore is already here)
- Code formatting configuration (you can adjust, say,line length and tabs via .clang-format)

>Relatively out-dated tooling in the old-school part of modern software development (particularly in, so-called, "unsafe languages" like C and C++) made the situation much worse than it could have been. For example, the Rust ecosystem is a great example of a user-friendly, modern, and well-engineered approach.  Convince newcomers to start their journey with C (or even with C++) notoriously hard because safe and modern programming languages (to be frankly) are a better choice. But all of them are built on top of or largely depend on C. To mitigate issues with creating and configuring C (self-study and pet) projects, this script was created.

---

## Getting Started

### Prerequisites

- Bash shell `sudo apt install bash`
- GCC compiler `sudo apt install build-essential`
- GDB debugger `sudo apt install gdb`
- Make build system `sudo apt install make`
- Clang-format `sudo apt install clang-format` (optional but recommended)
- [Mold linker](https://github.com/rui314/mold) (optional but recommended).
If you prefer not to install mold linker, you must delete flag "-fuse-ld=mold" in Makefile of your project to be compiled successfully
- [VS Code](https://code.visualstudio.com/) (optional but recommended)
- [Fish shell](https://fishshell.com/) `sudo apt install fish` (optional but recommended)
- Linux (Debian Sid, optional but recommended) or WSL (Windows Subsystem for Linux, maybe, not tested)

### Basic Usage

1. Edit a file named `entities.txt` depending on your current ideas to implement
2. Run the script:

```bash
./c_project_create.sh
```

### The `entities.txt` Format

The configuration file uses sections marked with hashtags (#). Here's the structure:

```txt
#Project_name
MyAwesomeProject

#Modules
name_of_modules1
name_of_modules2
name_of_modules3
...

#Functions
name_of_modules1 return_type name1(type param1, type param2, ...)
name_of_modules2 return_type name2(type param1, type param2, ...)
name_of_modules3 return_type name3(type param1, type param2, ...)
name_of_modules3 return_type name4(type param1, type param2, ...)
...

#data_structures
Name_of_structure1
Name_of_structure2
...

#errors
return_type name5(type param1, type param2, ...)
return_type name6(type param1, type param2, ...)
...

#const
type_of_const name_of_const1 = val1
type_of_const name_of_const2 = val2
type_of_const name_of_const3 = val3
...

#macros
NAME_OF_MACROS1(param1, param2, ...) (substitution_for_macros1)
NAME_OF_MACROS2 (substitution_for_macros2)
...

#enums
Name_of_union1
Name_of_union2
Name_of_union3
...

#unions
Name_of_union1
Name_of_union2
...

###END###
```

### Example Configuration

```txt
#Project_name
calculator

#Modules
math
display
input

#Functions
math double add(double a, double b)
math double subtract(double a, double b)
input char get_operation(void)

#data_structures
Calculation_history
Operation_queue

#errors
int invalid_operation(int code)

#const
double pi = 3.14159

#macros
SQUARE(x) ((x) * (x))

#enums
Operation
Status

#unions
Number
```

## Generated Project Structure

```txt
project_name/
├── bin/               # Compiled binaries
├── docs/             # Documentation
│   ├── api/
│   ├── dev_guide/
│   └── user_guide/
├── include/          # Header files
│   ├── data_structure/
│   ├── error/
│   ├── module/
│   ├── const.h
│   ├── enum.h
│   ├── macros.h
│   └── union.h
├── obj/              # Object files
├── src/             # Source files
│   ├── data_structure/
│   ├── error/
│   ├── module/
│   └── main.c
├── test/            # Test files
├── third_party/     # External dependencies
├── tool/            # Project tools
├── .clang-format    # Code formatting rules
├── .gitignore       # Git ignore rules
├── LICENSE          # Project license
├── Makefile        # Build configuration
└── README.md       # Project documentation
```

## Build System

Open shell in the root of the project directory and type:

```bash
make        # Build the project
make run    # Build and run the project
make test   # Build and run all tests
make clean  # Clean build files
make help   # Show available commands
```

## Tips for Newcomers

1. Start with a minimal configuration in `entities.txt` and gradually expand
2. Use the generated test infrastructure to practice test-driven development
3. Explore the generated directory structure to understand C project organization
4. Review the generated header files to learn about proper header file structure
5. Use the Makefile targets to understand the build process

## About AI and the future of software development

This project was created in tight collaboration with neural networks : Claude 3.5 Sonnet, ChatGPT and Grok. The list is arranged in order of value and amount of code generated.
The process took an infinite amount of small, manually revised, and tested step-by-step operations. Nobody's perfect—neither I, nor shell scripts, nor networks. So, be prepared to find bugs and errors (especially when editing "entities.txt " carelessly).
At the very least, deep integration of AI into software development and engineering is inevitable. The sooner you accept it, the better. But, on the other hand, at the moment, without your own knowledge and foundation, programming and problem-solving skills, Linux-user experience and the English language - all networks are rather useless. You can make sure of it quickly as soon as you get started on a project, a little more than 100 lines of code without actually understanding what's going on. So, be a wise and eager learner. Let yourself be a part of the future instead of remaining stuck in the past. And learn C (after that, Python and JavaScript will be a pleasant walk). When done, dive into Rust.

---

## Afterwords

There are no tools and environments capable of eliminating a reasonable desire to use modern languages in new projects and while learning process. Also, there are no tools and environments capable of eliminating an unreasonable desire of a language community not to set up its own standardized development ecosystem that are universal, easy-to-use and efficient. In addition to that, there are no tools or environments capable of eliminating legacy and backward compatibility problems. But mere presence of a simple logic structure, best practices, modern IDE (linters, language servers, AI support, shell), test-driven approach and a decent level of your own fundamental knowledge can make you code efficient and solid in any language.
