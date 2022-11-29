cmake_minimum_required(VERSION 3.5)
# need this for the qt app script
cmake_policy(SET CMP0087 NEW)
enable_testing(true)

project(Justly VERSION 0.1.0 LANGUAGES CXX)

# install into the same folder as the build directory
# so qt_generate_deploy_app_script will work on the build executable
set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}")
# cmake puts the build binary into this folder
set(CMAKE_INSTALL_BINDIR "$<CONFIG>")

# has the find module I added for gamma
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS Widgets Test)
find_package(Gamma REQUIRED)

add_executable(Tester
    src/Chord.cpp
    src/commands.cpp
    src/DefaultInstrument.cpp
    src/Editor.cpp
    src/Instrument.cpp
    src/TreeNode.cpp
    src/Note.cpp
    src/NoteChord.cpp
    src/Player.cpp
    src/Song.cpp
    src/TestEverything.cpp
    src/test.cpp
)

set_property(TARGET Tester PROPERTY "CXX_STANDARD" 23)
set_property(TARGET Tester PROPERTY "CXX_STANDARD_REQUIRED")
set_property(TARGET Tester PROPERTY "AUTOMOC" ON)

target_link_libraries(Tester PUBLIC Qt6::Widgets Qt6::Test Gamma::gamma)

add_test("Testing" Tester)

add_executable(Justly
    src/Chord.cpp
    src/commands.cpp
    src/DefaultInstrument.cpp
    src/Editor.cpp
    src/Instrument.cpp
    src/TreeNode.cpp
    src/Note.cpp
    src/NoteChord.cpp
    src/Player.cpp
    src/Song.cpp
    src/main.cpp
)

set_property(TARGET Justly PROPERTY "CXX_STANDARD" 23)
set_property(TARGET Justly PROPERTY "CXX_STANDARD_REQUIRED")
set_property(TARGET Justly PROPERTY "AUTOMOC" ON)

target_link_libraries(Justly PUBLIC Qt6::Widgets Qt6::Test Gamma::gamma)

install(TARGETS Justly
    RUNTIME_DEPENDENCIES
    # exclude whatever these are?
    PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-"
    # exclude 32 bit versions of dependencies maybe?
    POST_EXCLUDE_REGEXES ".*system32/.*\\.dll"
)

# so we don't have to run the deploy script manually
# if you are builing a debug configuration, you must manually delete the cd lines in windeploy.debug.bat
# I'm not sure why they are there
qt_generate_deploy_app_script(
    TARGET Justly
    FILENAME_VARIABLE release_deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT ${release_deploy_script})

