# 
# Module: KudzuTagLib_STRING.tcl
# Description: An example on how to write a Kudzu for TCL Tag Extension Library
# Author: Andrew Friedl
# License: MIT
#
namespace eval ::KudzuTagLib_STRING {

    # Library Class Definition
    oo::class create KudzuTag_UCASE {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]
            $node stackPush
            $node evalNodes
            $eng  setContent [string toupper [$eng getContent]]
            $node stackPop
        }
    }

    oo::class create KudzuTag_LCASE {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]
            $node stackPush
            $node evalNodes
            $eng  setContent [string tolower [$eng getContent]]
            $node stackPop;
        }
    }

    oo::class create KudzuTag_LTRIM {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]
            $node stackPush
            $node evalNodes
            $eng  setContent [string trimleft [$eng getContent]]
            $node stackPop;
        }
    }

    oo::class create KudzuTag_RTRIM {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]
            $node stackPush
            $node evalNodes
            $eng  setContent [string trimright [$eng getContent]]
            $node stackPop;
        }
    }

    oo::class create KudzuTag_TRIM {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]
            $node stackPush
            $node evalNodes
            $eng  setContent [string trim [$eng getContent]]
            $node stackPop;
        }
    }

    # Library Tag Import proc
    # invoked with ::KudzuTagLib_STRING::ImportTags tagLib
    proc ImportTags {tagLib} {
        # we pass the PATH to the functionality rather than instances
        $tagLib setTag "UCASE" "[namespace current]::KudzuTag_UCASE"
        $tagLib setTag "LCASE" "[namespace current]::KudzuTag_LCASE"
        $tagLib setTag "LTRIM" "[namespace current]::KudzuTag_LTRIM"
        $tagLib setTag "RTRIM" "[namespace current]::KudzuTag_RTRIM"
        $tagLib setTag "TRIM"  "[namespace current]::KudzuTag_TRIM"
    }
}