#!/bin/bash

# =============================================================================
# Helper Functions
# =============================================================================

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to ensure directory exists and is writable
ensure_directory() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        log_message "Created directory: $dir_path"
    fi
}

# Map of types to their corresponding include files
declare -A type_includes=(
    ["size_t"]="<stddef.h>"
    ["uint8_t"]="<stdint.h>"
    ["uint16_t"]="<stdint.h>"
    ["uint32_t"]="<stdint.h>"
    ["uint64_t"]="<stdint.h>"
    ["int8_t"]="<stdint.h>"
    ["int16_t"]="<stdint.h>"
    ["int32_t"]="<stdint.h>"
    ["int64_t"]="<stdint.h>"
    ["bool"]="<stdbool.h>"
    ["FILE"]="<stdio.h>"
)

# Function to extract types from function definition
extract_types() {
    local func_def="$1"
    local params
    local return_type
    local types=()
    
    # Extract parameters between parentheses
    params=$(echo "$func_def" | sed 's/.*(\(.*\)).*/\1/')
    
    # Extract return type (fixed: now properly extracts multi-word return types)
    return_type=$(echo "$func_def" | awk '{$NF=""; print $0}' | sed 's/(.*//' | xargs)
    types+=("$return_type")
    
    # Extract parameter types
    local IFS=','
    for param in $params; do
        local param_type
        param_type=$(echo "$param" | awk '{print $1}')
        types+=("$param_type")
    done
    
    echo "${types[@]}"
}

# Function to generate include statements for a file
generate_includes() {
    local types=("$@")
    local includes=()
    
    for type in "${types[@]}"; do
        if [[ -n "${type_includes[$type]}" ]]; then
            includes+=("${type_includes[$type]}")
        fi
    done
    
    # Remove duplicates and sort
    printf "%s\n" "${includes[@]}" | sort -u
}

# Function to add includes to a file
add_includes_to_file() {
    local file="$1"
    shift
    local includes=("$@")
    
    # Create file if it doesn't exist
    touch "$file"
    
    # Add includes at the top of the file
    if [[ ${#includes[@]} -gt 0 ]]; then
        local temp_file
        temp_file=$(mktemp)
        for include in "${includes[@]}"; do
            echo "#include $include" >> "$temp_file"
        done
        echo "" >> "$temp_file"
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
    fi
}

# =============================================================================
# Main Functions
# =============================================================================

# Function to create base directory structure
create_directory_structure() {
    local base_dir="$1"
    
    log_message "Creating base directory structure..."
    
    # Create all directories
    mkdir -p "${base_dir}"/{bin,obj,docs/{api,user_guide,dev_guide},include/{data_structure,error,module},src/{data_structure,error,module},test,tool,third_party}
    
    # Create base files
    touch "${base_dir}/include"/{macros,const,enum,union}.h
    touch "${base_dir}/src/main.c"
    touch "${base_dir}"/{.clang-format,.gitignore,LICENSE,Makefile,README.md}
    
    # Set up LICENSE content (fixed: added proper line ending)
    echo "GNU General Public License v2.0" > "${base_dir}/LICENSE"
    
    # Copy existing files if they exist
    [ -f "LICENSE" ] && cp -f LICENSE "$base_dir/"
    [ -f "README.md" ] && cp -f README.md "$base_dir/"

    # Create .gitignore with basic C ignores
    cat > "${base_dir}/.gitignore" << 'EOL'
# Object files
*.o

# Libraries
*.lib
*.a

# Executables
*.exe
*.out
bin/*

# Debug files
*.dSYM/

# Build directory
obj/*
EOL

# Create .gitignore with basic C ignores
    cat > "${base_dir}/Makefile" << 'EOL'
# Compiler settings
CC = gcc
CFLAGS = -Wall -Wextra -Wpedantic -std=c11 -Wconversion -Wshadow -Wfloat-equal -Wformat=2 -Wstrict-overflow=5 -g -Iinclude
LDFLAGS = -fuse-ld=mold

# Debug settings
DEBUG_CFLAGS = -ggdb3 -O0 -DDEBUG

# Directories
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin
TEST_DIR = test
DEBUG_OBJ_DIR = obj/debug
DEBUG_BIN_DIR = bin/debug

# Find all source files
SRCS = $(shell find $(SRC_DIR) -name '*.c')
OBJS = $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
DEBUG_OBJS = $(SRCS:$(SRC_DIR)/%.c=$(DEBUG_OBJ_DIR)/%.o)

# Test sources and binaries
TEST_SRCS = $(wildcard $(TEST_DIR)/*.c)
TEST_BINS = $(TEST_SRCS:$(TEST_DIR)/%.c=$(BIN_DIR)/%)
DEBUG_TEST_BINS = $(TEST_SRCS:$(TEST_DIR)/%.c=$(DEBUG_BIN_DIR)/%)

# Main targets
TARGET = $(BIN_DIR)/main
DEBUG_TARGET = $(DEBUG_BIN_DIR)/main

# Default target
all: create_dirs $(TARGET)

# Debug target
debug: CFLAGS += $(DEBUG_CFLAGS)
debug: create_debug_dirs $(DEBUG_TARGET)

# Ensure necessary directories exist
create_dirs:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(OBJ_DIR)
	@find $(SRC_DIR) -type d -exec mkdir -p $(OBJ_DIR)/{} \;

create_debug_dirs:
	@mkdir -p $(DEBUG_BIN_DIR)
	@mkdir -p $(DEBUG_OBJ_DIR)
	@find $(SRC_DIR) -type d -exec mkdir -p $(DEBUG_OBJ_DIR)/{} \;

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(DEBUG_OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Link the main program
$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

$(DEBUG_TARGET): $(DEBUG_OBJS)
	$(CC) $(DEBUG_OBJS) $(LDFLAGS) -o $@

# Compile and link test files
$(BIN_DIR)/%: $(TEST_DIR)/%.c $(filter-out $(OBJ_DIR)/main.o,$(OBJS))
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

$(DEBUG_BIN_DIR)/%: $(TEST_DIR)/%.c $(filter-out $(DEBUG_OBJ_DIR)/main.o,$(DEBUG_OBJS))
	@mkdir -p $(DEBUG_BIN_DIR)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

# Build all tests
tests: create_dirs $(TEST_BINS)

debug-tests: CFLAGS += $(DEBUG_CFLAGS)
debug-tests: create_debug_dirs $(DEBUG_TEST_BINS)

# Run all tests
test: tests
	@for test in $(TEST_BINS); do \
		echo "Running $$test..."; \
		$$test || exit 1; \
	done

debug-test: debug-tests
	@for test in $(DEBUG_TEST_BINS); do \
		echo "Running $$test..."; \
		$$test || exit 1; \
	done

# Run the main program
run: all
	@echo "Running $(TARGET)..."
	@$(TARGET)

debug-run: debug
	@echo "Running $(DEBUG_TARGET)..."
	@$(DEBUG_TARGET)

# Clean build files
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

# Show help
help:
	@echo "Available targets:"
	@echo "  all         : Build main program (default)"
	@echo "  debug       : Build main program with debug symbols"
	@echo "  clean       : Remove all built files"
	@echo "  run         : Build and launch the project"
	@echo "  debug-run   : Build and launch with debug symbols"
	@echo "  test        : Build and run all tests"
	@echo "  debug-test  : Build and run all tests with debug symbols"
	@echo "  help        : Show this help message"

.PHONY: all debug create_dirs create_debug_dirs clean run debug-run test debug-test tests debug-tests help
EOL

# Create a simple main.c
    cat > "$project_name/src/main.c" << 'EOL'
#include <stdio.h>

int main(int argc, char *argv[]) {
    (void)argc;  // Unused parameter
    (void)argv;  // Unused parameter
    
    printf("Program started\n");
    
    return 0;
}
EOL

    # Create .clang-format
    cat > "${base_dir}/.clang-format" << 'EOL'
---
BasedOnStyle: Google
IndentWidth: 2
ColumnLimit: 100
---
EOL
    
    log_message "Base directory structure created successfully"
}

# Function to parse modules section
parse_modules() {
    log_message "Parsing modules section..."
    local in_modules_section=false
    local modules=()

    while IFS= read -r line; do
        if [[ "$line" == "#Modules" ]]; then
            in_modules_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#Modules" ]]; then
            in_modules_section=false
            continue
        fi
        
        if [[ "$in_modules_section" == true ]] && [[ -n "$line" ]]; then
            modules+=("$line")
        fi
    done < "entities.txt"

    for module in "${modules[@]}"; do
        if [[ -n "$module" ]]; then
            log_message "Creating directories for module: $module"
            ensure_directory "${project_name}/src/module/$module"
            ensure_directory "${project_name}/include/module/$module"
        fi
    done
}

# Function to parse and insert function declarations
parse_and_insert_declarations() {
    log_message "Parsing function declarations and generating files..."
    local in_functions_section=false

    # Define a map of types to required includes
    declare -A type_includes=(
        ["size_t"]="<stddef.h>"
        ["void"]="<stddef.h>"
        ["bool"]="<stdbool.h>"
        ["FILE"]="<stdio.h>"
        ["uint8_t"]="<stdint.h>"
        ["uint16_t"]="<stdint.h>"
        ["uint32_t"]="<stdint.h>"
        ["uint64_t"]="<stdint.h>"
        ["int8_t"]="<stdint.h>"
        ["int16_t"]="<stdint.h>"
        ["int32_t"]="<stdint.h>"
        ["int64_t"]="<stdint.h>"
    )

    while IFS= read -r line; do
        if [[ "$line" == "#Functions" ]]; then
            in_functions_section=true
            continue
        fi

        if [[ "$line" == "#"* ]] && [[ "$in_functions_section" == true ]]; then
            in_functions_section=false
            continue
        fi

        if [[ "$in_functions_section" == true ]] && [[ -n "$line" ]]; then
            # Extract components using awk
            local module_name
            local return_type
            local function_signature
            local function_name

            module_name=$(echo "$line" | awk '{print $1}')
            return_type=$(echo "$line" | awk '{print $2}')
            function_signature=$(echo "$line" | awk '{print substr($0, index($0, $3))}')
            function_name=$(echo "$function_signature" | cut -d'(' -f1)

            # Collect types (return type + parameter types) to determine includes
            local param_types=()
            param_types+=("$return_type")
            while IFS=',' read -ra params; do
                for param in "${params[@]}"; do
                    param_types+=($(echo "$param" | awk '{print $1}'))
                done
            done <<< "$(echo "$function_signature" | sed 's/.*(\(.*\)).*/\1/')"

            # Determine includes
            local includes=()
            for type in "${param_types[@]}"; do
                if [[ -n "${type_includes[$type]}" && ! " ${includes[*]} " =~ " ${type_includes[$type]} " ]]; then
                    includes+=("${type_includes[$type]}")
                fi
            done

            # Ensure directories exist
            local header_dir="${project_name}/include/module/${module_name}"
            local source_dir="${project_name}/src/module/${module_name}"
            local test_dir="${project_name}/test"
            ensure_directory "$header_dir"
            ensure_directory "$source_dir"
            ensure_directory "$test_dir"

            # Generate header file
            local header_path="${header_dir}/${function_name}.h"
            if [[ ! -f "$header_path" ]]; then
                log_message "Creating header file: $header_path"
                {
                    echo "#ifndef MODULE_${module_name^^}_${function_name^^}_H"
                    echo "#define MODULE_${module_name^^}_${function_name^^}_H"
                    echo
                    for include in "${includes[@]}"; do
                        echo "#include $include"
                    done
                    echo
                    echo "/**"
                    echo " * @brief Function declaration for ${function_name}."
                    echo " */"
                    echo "${return_type} ${function_signature};"
                    echo
                    echo "#endif // MODULE_${module_name^^}_${function_name^^}_H"
                } > "$header_path"
            fi

            # Generate source file
            local source_path="${source_dir}/${function_name}.c"
            if [[ ! -f "$source_path" ]]; then
                log_message "Creating source file: $source_path"
                cat > "$source_path" << EOL
#include "module/${module_name}/${function_name}.h"
#include <stdio.h>

/**
 * @brief Function definition for ${function_name}.
 */
${return_type} ${function_signature} {
    // TODO: Implement the logic for ${function_name}
    return (${return_type%% *})0; // Temporary return for compilation
}
EOL
            fi

            # Generate test file
            local test_file="${test_dir}/test_${function_name}.c"
            if [[ ! -f "$test_file" ]]; then
                log_message "Creating test file: $test_file"
                cat > "$test_file" << EOL
#include "module/${module_name}/${function_name}.h"
#include <assert.h>
#include <stdio.h>

/**
 * @brief Test function for ${function_name}.
 */
void test_${function_name}() {
    // TODO: Add proper test cases for ${function_name}
    printf("Running tests for ${function_name}\\n");
    assert(1); // Placeholder assertion
}

int main() {
    test_${function_name}();
    printf("All tests passed for ${function_name}\\n");
    return 0;
}
EOL
            fi
        fi
    done < "entities.txt"
}

# Function to parse and insert data structure declarations
parse_and_insert_data_structures() {
    log_message "Inserting data structure declarations..."
    local in_data_structures_section=false
    
    while IFS= read -r line; do
        if [[ "$line" == "#data_structures" ]]; then
            in_data_structures_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#data_structures" ]]; then
            in_data_structures_section=false
            continue
        fi
        
        if [[ "$in_data_structures_section" == true ]] && [[ -n "$line" ]]; then
            local struct_name
            struct_name=$(echo "$line" | xargs)
            
            if [[ -n "$struct_name" ]]; then
                local header_dir="${project_name}/include/data_structure"
                local source_dir="${project_name}/src/data_structure"
                
                ensure_directory "$header_dir"
                ensure_directory "$source_dir"
                
                local header_path="${header_dir}/${struct_name}.h"
                local source_path="${source_dir}/${struct_name}.c"
                
                # Create header file
                log_message "Creating header file: $header_path"
                cat > "$header_path" << EOL
#ifndef DATA_STRUCTURE_${struct_name}_H
#define DATA_STRUCTURE_${struct_name}_H

#include <stddef.h>

/**
 * @brief Structure definition for ${struct_name}
 */
typedef struct ${struct_name} {
    int id;                  /* Unique identifier */
    void *data;             /* Pointer to associated data */
    size_t size;            /* Size of the data */
    struct ${struct_name} *next;  /* Pointer to next element */
} ${struct_name}_t;

/**
 * @brief Initialize a new ${struct_name}
 * @return Initialized ${struct_name} structure or NULL on failure
 */
${struct_name}_t *${struct_name}_init(void);

/**
 * @brief Clean up and free a ${struct_name}
 * @param structure Pointer to the structure to free
 */
void ${struct_name}_destroy(${struct_name}_t *structure);

#endif // DATA_STRUCTURE_${struct_name}_H
EOL

                # Create source file
                log_message "Creating source file: $source_path"
                cat > "$source_path" << EOL
#include "data_structure/${struct_name}.h"
#include <stdlib.h>

${struct_name}_t *${struct_name}_init(void) {
    ${struct_name}_t *structure = malloc(sizeof(${struct_name}_t));
    if (structure == NULL) {
        return NULL;
    }
    
    structure->id = 0;
    structure->data = NULL;
    structure->size = 0;
    structure->next = NULL;
    
    return structure;
}

void ${struct_name}_destroy(${struct_name}_t *structure) {
    if (structure == NULL) {
        return;
    }
    
    free(structure->data);
    free(structure);
}
EOL
                
                chmod 644 "$header_path"
                chmod 644 "$source_path"
            fi
        fi
    done < "entities.txt"
}

# Function to parse and insert error declarations
parse_and_insert_errors() {
    log_message "Inserting error declarations..."
    local in_errors_section=false

    while IFS= read -r line; do
        # Start the section when encountering #errors (case-insensitive)
        if [[ "${line,,}" == "#errors" ]]; then
            in_errors_section=true
            continue
        fi

        # Exit the section when encountering another comment section
        if [[ "$line" == "#"* ]] && [[ "${line,,}" != "#errors" ]]; then
            in_errors_section=false
            continue
        fi

        # If inside the #errors section and line is not empty
        if [[ "$in_errors_section" == true ]] && [[ -n "$line" ]]; then
            # Extract components using awk
            local return_type=$(echo "$line" | awk '{print $1}')
            local rest_of_line=$(echo "$line" | cut -d' ' -f2-)

            # Extract function name from the declaration (e.g., 'handle_error' from 'handle_error(int code)')
            local function_name=$(echo "$rest_of_line" | cut -d'(' -f1)

            if [[ -n "$return_type" ]] && [[ -n "$function_name" ]] && [[ -n "$rest_of_line" ]]; then
                # Define directories for errors
                local header_dir="${project_name}/include/error"
                local source_dir="${project_name}/src/error"

                # Ensure directories exist
                ensure_directory "$header_dir"
                ensure_directory "$source_dir"

                # Define file paths
                local header_path="${header_dir}/${function_name}.h"
                local source_path="${source_dir}/${function_name}.c"

                # Check if files already exist and are empty
                local regenerate_header=false
                local regenerate_source=false
                if [[ -f "$header_path" ]]; then
                    if [[ ! -s "$header_path" ]]; then
                        log_message "Empty header file detected: $header_path. Regenerating."
                        regenerate_header=true
                    else
                        log_message "Skipping $header_path, non-empty file already exists."
                    fi
                else
                    regenerate_header=true
                fi

                if [[ -f "$source_path" ]]; then
                    if [[ ! -s "$source_path" ]]; then
                        log_message "Empty source file detected: $source_path. Regenerating."
                        regenerate_source=true
                    else
                        log_message "Skipping $source_path, non-empty file already exists."
                    fi
                else
                    regenerate_source=true
                fi

                # Create header file with the function declaration if needed
                if [[ "$regenerate_header" == true ]]; then
                    log_message "Creating header file: $header_path"
                    cat > "$header_path" << EOL
#ifndef ERROR_${function_name^^}_H
#define ERROR_${function_name^^}_H

/**
 * @brief Declaration of the error handling function: ${function_name}
 *
 * @param code Error code
 * @return ${return_type} Description of the return value
 */
${return_type} ${rest_of_line};

#endif // ERROR_${function_name^^}_H
EOL
                    chmod 644 "$header_path"
                fi

                # Create source file with the function definition if needed
                if [[ "$regenerate_source" == true ]]; then
                    log_message "Creating source file: $source_path"
                    cat > "$source_path" << EOL
#include "error/${function_name}.h"

/**
 * @brief Implementation of the error handling function: ${function_name}
 *
 * @param code Error code
 * @return ${return_type} Description of the return value
 */
${return_type} ${rest_of_line} {
    // TODO: Implement error handling logic
}
EOL
                    chmod 644 "$source_path"
                fi
            fi
        fi
    done < "entities.txt"
}

# Function to parse and insert constants
parse_and_insert_constants() {
    log_message "Parsing constants section and inserting into const.h..."
    local in_const_section=false
    local const_declarations=()
    local const_types=()
    
    while IFS= read -r line; do
        if [[ "$line" == "#const" ]]; then
            in_const_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#const" ]]; then
            in_const_section=false
            continue
        fi
        
        if [[ "$in_const_section" == true ]] && [[ -n "$line" ]]; then
            const_declarations+=("$line")
            local const_type
            const_type=$(echo "$line" | awk '{print $1}')
            const_types+=("$const_type")
        fi
    done < "entities.txt"

    if [ ${#const_declarations[@]} -gt 0 ]; then
        local const_header_path="${project_name}/include/const.h"
        ensure_directory "$(dirname "$const_header_path")"
        
        # Create proper header guard name (sanitized)
        local guard_name="${project_name^^}_CONST_H"
        guard_name=${guard_name//[^A-Z0-9_]/_}
        
        {
            echo "#ifndef ${guard_name}"
            echo "#define ${guard_name}"
            echo
            
            # Generate includes from types
            local includes
            includes=($(generate_includes "${const_types[@]}"))
            for include in "${includes[@]}"; do
                echo "#include $include"
            done
            
            [[ ${#includes[@]} -gt 0 ]] && echo
            
            # Write constant declarations
            for constant in "${const_declarations[@]}"; do
                local type
                local name
                local value
                
                type=$(echo "$constant" | awk '{print $1}')
                name=$(echo "$constant" | awk '{print $2}')
                value=$(echo "$constant" | awk -F'=' '{print $2}' | sed 's/^ *//')
                
                echo "/** @brief ${name} constant */"
                echo "const ${type} ${name} = ${value};"
                echo
            done
            
            echo "#endif /* ${guard_name} */"
            
        } > "$const_header_path"
        
        chmod 644 "$const_header_path"
        log_message "Constants written to $const_header_path"
    else
        log_message "No constants found to insert"
    fi
}

# Function to parse and insert macros
parse_and_insert_macros() {
    log_message "Parsing macros section and inserting into macros.h..."
    local in_macros_section=false
    local macro_declarations=()
    
    while IFS= read -r line; do
        if [[ "$line" == "#macros" ]]; then
            in_macros_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#macros" ]]; then
            in_macros_section=false
            continue
        fi
        
        if [[ "$in_macros_section" == true ]] && [[ -n "$line" ]]; then
            local macro_name
            local substitution
            
            macro_name=$(echo "$line" | awk '{print $1}')
            substitution=$(echo "$line" | sed -e "s/^[^ ]* //")
            
            # Add comment for macro documentation
            macro_declarations+=("/** @brief ${macro_name} macro definition */")
            macro_declarations+=("#define ${macro_name} ${substitution}")
            macro_declarations+=("")
        fi
    done < "entities.txt"

    if [ ${#macro_declarations[@]} -gt 0 ]; then
        local macros_header_path="${project_name}/include/macros.h"
        ensure_directory "$(dirname "$macros_header_path")"
        
        local guard_name="${project_name^^}_MACROS_H"
        guard_name=${guard_name//[^A-Z0-9_]/_}
        
        {
            echo "#ifndef ${guard_name}"
            echo "#define ${guard_name}"
            echo
            
            printf "%s\n" "${macro_declarations[@]}"
            
            echo "#endif /* ${guard_name} */"
            
        } > "$macros_header_path"
        
        chmod 644 "$macros_header_path"
        log_message "Macros written to $macros_header_path"
    else
        log_message "No macros found to insert"
    fi
}

# Function to parse and insert enums
parse_and_insert_enums() {
    log_message "Parsing enums section and inserting into enum.h..."
    local in_enums_section=false
    local enum_declarations=()
    
    while IFS= read -r line; do
        if [[ "$line" == "#enums" ]]; then
            in_enums_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#enums" ]]; then
            in_enums_section=false
            continue
        fi
        
        if [[ "$in_enums_section" == true ]] && [[ -n "$line" ]]; then
            local enum_name
            enum_name=$(echo "$line" | xargs)
            if [[ -n "$enum_name" ]]; then
                enum_declarations+=(
"/**
 * @brief Enumeration type for ${enum_name}
 */
typedef enum ${enum_name} {
    ${enum_name}_NONE = 0,    /**< Default null value */
    ${enum_name}_DEFAULT = 1, /**< Default state */
    ${enum_name}_MAX         /**< Maximum value marker */
} ${enum_name}_t;")
            fi
        fi
    done < "entities.txt"

    if [ ${#enum_declarations[@]} -gt 0 ]; then
        local enum_header_path="${project_name}/include/enum.h"
        ensure_directory "$(dirname "$enum_header_path")"
        
        local guard_name="${project_name^^}_ENUM_H"
        guard_name=${guard_name//[^A-Z0-9_]/_}
        
        {
            echo "#ifndef ${guard_name}"
            echo "#define ${guard_name}"
            echo
            
            printf "%s\n\n" "${enum_declarations[@]}"
            
            echo "#endif /* ${guard_name} */"
            
        } > "$enum_header_path"
        
        chmod 644 "$enum_header_path"
        log_message "Enums written to $enum_header_path"
    else
        log_message "No enums found to insert"
    fi
}

# Function to parse and insert unions
parse_and_insert_unions() {
    log_message "Parsing unions section and inserting into union.h..."
    local in_unions_section=false
    local union_declarations=()
    
    while IFS= read -r line; do
        if [[ "$line" == "#unions" ]]; then
            in_unions_section=true
            continue
        fi
        
        if [[ "$line" == "#"* ]] && [[ "$line" != "#unions" ]]; then
            in_unions_section=false
            continue
        fi
        
        if [[ "$in_unions_section" == true ]] && [[ -n "$line" ]]; then
            local union_name
            union_name=$(echo "$line" | xargs)
            if [[ -n "$union_name" ]]; then
                union_declarations+=(
"/**
 * @brief Union type for ${union_name}
 */
typedef union ${union_name} {
    int32_t i32;     /**< 32-bit signed integer */
    uint32_t u32;    /**< 32-bit unsigned integer */
    float f32;       /**< 32-bit floating point */
    void *ptr;       /**< Generic pointer */
} ${union_name}_t;")
            fi
        fi
    done < "entities.txt"

    if [ ${#union_declarations[@]} -gt 0 ]; then
        local union_header_path="${project_name}/include/union.h"
        ensure_directory "$(dirname "$union_header_path")"
        
        local guard_name="${project_name^^}_UNION_H"
        guard_name=${guard_name//[^A-Z0-9_]/_}
        
        {
            echo "#ifndef ${guard_name}"
            echo "#define ${guard_name}"
            echo
            echo "#include <stdint.h>"
            echo
            
            printf "%s\n\n" "${union_declarations[@]}"
            
            echo "#endif /* ${guard_name} */"
            
        } > "$union_header_path"
        
        chmod 644 "$union_header_path"
        log_message "Unions written to $union_header_path"
    else
        log_message "No unions found to insert"
    fi
}

# Final script section with organized main execution flow

#====================================================
# Main execution
#====================================================

# Function to display usage information
display_usage() {
    echo "Usage:"
    echo "  cd $project_name"
    echo "  make        # Build the project"
    echo "  make run    # Build/Re-build (if needed) and run the project"
    echo "  make test   # Build/Re-build (if needed) and run tests"
    echo "  make clean  # Clean build files"
    echo "  make help   # Display comprehensive help message"
}

# Function to copy necessary files to tool directory
copy_tool_files() {
    local tool_dir="$project_name/tool"
    ensure_directory "$tool_dir"
    
    # Copy script files
    cp "$0" "$tool_dir/copy.sh"
    chmod 755 "$tool_dir/copy.sh"
    
    # Copy configuration files if they exist
    [ -f "entities.txt" ] && cp "entities.txt" "$tool_dir/"
    [ -f "structure.txt" ] && cp "structure.txt" "$tool_dir/"
    
    log_message "Tool files copied successfully"
}

# Main execution flow
main() {
    # Check if entities.txt exists
    if [ ! -f "entities.txt" ]; then
        log_message "Error: entities.txt file not found!"
        exit 1
    fi

    # Read and validate project name
    project_name=$(sed -n '2p' entities.txt | xargs)
    if [ -z "$project_name" ]; then
        log_message "Error: Invalid or empty project name in entities.txt"
        exit 1
    fi

    log_message "Starting project creation for: $project_name"

    # Check if project directory exists and handle it
    if [ -d "$project_name" ]; then
        log_message "Directory '$project_name' already exists. Deleting all files and folders inside it..."
        rm -rf "${project_name:?}"/*
    fi

    # Execute all creation functions in order
    create_directory_structure "$project_name"
    parse_modules
    parse_and_insert_declarations
    parse_and_insert_data_structures
    parse_and_insert_errors
    parse_and_insert_constants
    parse_and_insert_macros
    parse_and_insert_enums
    parse_and_insert_unions

    # Copy necessary files to tool directory
    copy_tool_files

    # Display completion message and usage information
    log_message "Project creation completed successfully"
    display_usage
}

# Execute main function
main "$@"
