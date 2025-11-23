cmake_minimum_required(VERSION 3.16)

project(Tool VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network QuickControls2 SerialPort)

qt_standard_project_setup(REQUIRES 6.8)

# 1. 生成资源文件 logo.rc (如果 estun.ico 在项目根目录)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/logo.rc" "IDI_ICON1 ICON \"${CMAKE_CURRENT_SOURCE_DIR}/estun.ico\"")

# =========================================================
# 自动复制 resources 文件夹 (带检查)
# =========================================================
set(RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")

if(EXISTS "${RESOURCE_DIR}")
    # 1. 确保构建目录下有 resources 文件夹 (CMake 会自动创建)
    # 2. 复制文件
    file(COPY ${RESOURCE_DIR} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    message(STATUS "Copied resources folder to build directory.")
else()
    message(WARNING "Resources folder not found at ${RESOURCE_DIR}. Manuals will not be available.")
    # 可选：创建一个空的，防止运行报错
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/resources)
endif()


# 将源文件加入可执行程序
qt_add_executable(Tool
    main.cpp
    "${CMAKE_CURRENT_BINARY_DIR}/logo.rc"
)

qt_add_qml_module(Tool
    URI Tool
    QML_FILES
        Main.qml
        Page/PageConnect.qml
        Page/PageMonitor.qml
        Components/CustomButton.qml
        Components/CustomMenuBar.qml
        Page/PageMove.qml
        Page/PageVariable.qml
        Page/PageIORegister.qml
        Page/PageSerial.qml
        Page/PageUserManual.qml
    SOURCES
        src/Robotclient.h
        src/Robotclient.cpp
        src/serialclient.h
        src/serialclient.cpp

    RESOURCES
        icon.qrc
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(Tool PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.Tool
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(Tool
    PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network Qt6::QuickControls2 Qt6::SerialPort
)

include(GNUInstallDirs)
install(TARGETS Tool
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
