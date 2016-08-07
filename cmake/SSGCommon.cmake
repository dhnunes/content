set(SSG_SHARED "${CMAKE_SOURCE_DIR}/shared")
set(SSG_SHARED_TRANSFORMS "${SSG_SHARED}/transforms")
set(SSG_SHARED_UTILS "${SSG_SHARED}/utils")

macro(ssg_xsltproc INPUT XSLT OUTPUT)
    add_custom_command(
        OUTPUT ${OUTPUT}
        COMMAND ${XSLTPROC_EXECUTABLE} --output ${OUTPUT} ${XSLT} ${INPUT}
        MAIN_DEPENDENCY ${INPUT}
        DEPENDS ${XSLT}
    )
endmacro()

macro(ssg_build_guide_xml PRODUCT)
    if(OSCAP_SVG_SUPPORT EQUAL 0)
        ssg_xsltproc(
            ${CMAKE_CURRENT_SOURCE_DIR}/input/guide.xml
            ${SSG_SHARED_TRANSFORMS}/includelogo.xslt
            ${CMAKE_CURRENT_BINARY_DIR}/guide.xml
        )
    else()
        add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/guide.xml
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/input/guide.xml ${CMAKE_CURRENT_BINARY_DIR}/guide.xml
            MAIN_DEPENDENCY ${CMAKE_CURRENT_SOURCE_DIR}/input/guide.xml
        )
    endif()
endmacro()

macro(ssg_build_shorthand_xml PRODUCT)
    file(GLOB AUXILIARY_DEPS "${CMAKE_CURRENT_SOURCE_DIR}/input/auxiliary/*.xml")
    file(GLOB PROFILE_DEPS "${CMAKE_CURRENT_SOURCE_DIR}/input/profiles/*.xml")
    file(GLOB XCCDF_RULE_DEPS "${CMAKE_CURRENT_SOURCE_DIR}/input/xccdf/**/*.xml")

    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml
        COMMAND ${XSLTPROC_EXECUTABLE} --stringparam SHARED_RP ${SSG_SHARED} --output ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml ${CMAKE_CURRENT_SOURCE_DIR}/input/guide.xslt ${CMAKE_CURRENT_BINARY_DIR}/guide.xml
        COMMAND ${XMLLINT_EXECUTABLE} --format --output ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml
        MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/guide.xml
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/input/guide.xslt ${AUXILIARY_DEPS} ${PROFILE_DEPS} ${XCCDF_RULE_DEPS}
    )
endmacro()

macro(ssg_build_unlinked_xccdf PRODUCT)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml
        COMMAND ${XSLTPROC_EXECUTABLE} --stringparam ssg_version ${SSG_VERSION} --output ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml ${CMAKE_CURRENT_SOURCE_DIR}/transforms/shorthand2xccdf.xslt ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml
        COMMAND ${OSCAP_EXECUTABLE} xccdf resolve -o ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml
        COMMAND ${SSG_SHARED_UTILS}/unselect-empty-xccdf-groups.py --input ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml --output ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml
        COMMAND ${OSCAP_EXECUTABLE} xccdf resolve -o ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml ${CMAKE_CURRENT_BINARY_DIR}/xccdf-unlinked-resolved.xml
        MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/shorthand.xml
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/transforms/shorthand2xccdf.xslt ${CMAKE_CURRENT_SOURCE_DIR}/transforms/constants.xslt ${SSG_SHARED_TRANSFORMS}/shared_constants.xslt
        #DEPENDS ${CMAKE_BINARY_DIR}/contributors.xml
    )
endmacro()
