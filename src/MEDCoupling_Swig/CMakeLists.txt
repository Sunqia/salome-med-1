# Copyright (C) 2012-2013  CEA/DEN, EDF R&D
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

INCLUDE(${SALOME_MACROS_DIR}/InstallAndCompilePythonFile.cmake)

FIND_PACKAGE(SWIG REQUIRED)
INCLUDE(${SWIG_USE_FILE})

SET_SOURCE_FILES_PROPERTIES(MEDCoupling.i PROPERTIES CPLUSPLUS ON)
SET_SOURCE_FILES_PROPERTIES(MEDCoupling.i PROPERTIES SWIG_DEFINITIONS "-shadow")

SET (MEDCoupling_SWIG_DPYS_FILES
    MEDCouplingCommon.i
    MEDCouplingFinalize.i
    MEDCouplingTypemaps.i)   

INCLUDE_DIRECTORIES(
  ${PYTHON_INCLUDE_DIRS}
  ${PTHREAD_INCLUDE_DIRS} # pthread dependancy due to python2.7 library
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../MEDCoupling
  ${CMAKE_CURRENT_SOURCE_DIR}/../INTERP_KERNEL
  ${CMAKE_CURRENT_SOURCE_DIR}/../INTERP_KERNEL/Bases
  ${CMAKE_CURRENT_SOURCE_DIR}/../INTERP_KERNEL/Geometric2D
  ${CMAKE_CURRENT_SOURCE_DIR}/../INTERP_KERNEL/ExprEval
  ${CMAKE_CURRENT_SOURCE_DIR}/../INTERP_KERNEL/GaussPoints
  )

# _ABR_ Ensure dependency mechanism on all SWIG files and headers
SET (SWIG_MODULE_MEDCoupling_EXTRA_DEPS ${MEDCoupling_SWIG_DPYS_FILES} 
    ${medcoupling_HEADERS_HXX} ${medcoupling_HEADERS_TXX}
    ${interpkernel_HEADERS_HXX} ${interpkernel_HEADERS_TXX})

SWIG_ADD_MODULE(MEDCoupling python MEDCoupling.i)
SWIG_LINK_LIBRARIES(MEDCoupling ${PYTHON_LIBS} ${PLATFORM_LIBS} medcoupling)
SET_TARGET_PROPERTIES(${SWIG_MODULE_MEDCoupling_REAL_NAME} PROPERTIES COMPILE_FLAGS "${PLATFORM_DEFINITIONS}")

SET_SOURCE_FILES_PROPERTIES(MEDCouplingRemapper.i PROPERTIES CPLUSPLUS ON)
SET_SOURCE_FILES_PROPERTIES(MEDCouplingRemapper.i PROPERTIES SWIG_DEFINITIONS "-shadow")

# _ABR_ Ensure dependency mechanism on all SWIG files and headers
SET (SWIG_MODULE_MEDCouplingRemapper_EXTRA_DEPS ${MEDCoupling_SWIG_DPYS_FILES}
    ${medcoupling_HEADERS_HXX} ${medcoupling_HEADERS_TXX}
    ${interpkernel_HEADERS_HXX} ${interpkernel_HEADERS_TXX})

SWIG_ADD_MODULE(MEDCouplingRemapper python MEDCouplingRemapper.i)
SWIG_LINK_LIBRARIES(MEDCouplingRemapper ${PYTHON_LIBS} medcouplingremapper)
SET_TARGET_PROPERTIES(${SWIG_MODULE_MEDCouplingRemapper_REAL_NAME} PROPERTIES COMPILE_FLAGS "${PLATFORM_DEFINITIONS}")

IF(${MACHINE} STREQUAL WINDOWS)
  SET_TARGET_PROPERTIES(_MEDCouplingRemapper PROPERTIES DEBUG_OUTPUT_NAME _MEDCouplingRemapper_d)
  SET_TARGET_PROPERTIES(_MEDCoupling PROPERTIES DEBUG_OUTPUT_NAME _MEDCoupling_d)
ENDIF(${MACHINE} STREQUAL WINDOWS)
INSTALL(TARGETS ${SWIG_MODULE_MEDCoupling_REAL_NAME} ${SWIG_MODULE_MEDCouplingRemapper_REAL_NAME} DESTINATION ${MED_salomelib_LIBS})

SET(PYFILES_TO_INSTALL ${CMAKE_CURRENT_BINARY_DIR}/MEDCoupling.py ${CMAKE_CURRENT_BINARY_DIR}/MEDCouplingRemapper.py ${CMAKE_CURRENT_SOURCE_DIR}/libMEDCoupling_Swig.py)
INSTALL_AND_COMPILE_PYTHON_FILE("${PYFILES_TO_INSTALL}" ${MED_salomescript_PYTHON})

INSTALL(FILES MEDCoupling.i MEDCouplingCommon.i MEDCouplingFinalize.i MEDCouplingRemapper.i MEDCouplingTypemaps.i DESTINATION ${MED_salomeinclude_HEADERS})
INSTALL(FILES MEDCouplingBasicsTest.py MEDCouplingRemapperTest.py MEDCouplingDataForTest.py DESTINATION ${MED_salomescript_PYTHON})

ADD_TEST(MEDCouplingBasicsTest ${PYTHON_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/MEDCouplingBasicsTest.py)
ADD_TEST(MEDCouplingExamplesTest ${PYTHON_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/MEDCouplingExamplesTest.py)
ADD_TEST(MEDCouplingRemapperTest ${PYTHON_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/MEDCouplingRemapperTest.py)