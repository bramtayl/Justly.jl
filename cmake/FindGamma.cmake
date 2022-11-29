include(FindPackageHandleStandardArgs)

find_dependency(SndFile REQUIRED)
find_dependency(portaudio REQUIRED)

find_path(Gamma_INCLUDE_DIR
  NAMES "Gamma/Gamma.h"
  PATHS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include"
  REQUIRED
)

add_library(Gamma::gamma SHARED IMPORTED)
target_include_directories(Gamma::gamma INTERFACE "${Gamma_INCLUDE_DIR}")

if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  # gamma uses a different min/max
  target_compile_definitions(Gamma::gamma INTERFACE "NOMINMAX")
endif()

find_library(Gamma_LIBRARY_RELEASE
  NAMES "gamma"
  PATHS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib/"
  NO_DEFAULT_PATH
  REQUIRED
)

find_library(Gamma_LIBRARY_DEBUG
  NAMES "gamma"
  PATHS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib/"
  NO_DEFAULT_PATH
  REQUIRED
)

set_target_properties(Gamma::gamma PROPERTIES
  IMPORTED_CONFIGURATIONS "DEBUG;RELEASE"
  INTERFACE_LINK_LIBRARIES "portaudio;SndFile::sndfile"
)

IF (WIN32)
  set_target_properties(Gamma::gamma PROPERTIES
    IMPORTED_IMPLIB_RELEASE "${Gamma_LIBRARY_RELEASE}"
    IMPORTED_IMPLIB_DEBUG "${Gamma_LIBRARY_DEBUG}"
  )
ELSE()
  set_target_properties(Gamma::gamma PROPERTIES
    IMPORTED_LOCATION_RELEASE "${Gamma_LIBRARY_RELEASE}"
    IMPORTED_LOCATION_DEBUG "${Gamma_LIBRARY_DEBUG}"
  )
ENDIF()
