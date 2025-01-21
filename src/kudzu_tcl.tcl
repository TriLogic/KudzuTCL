#
# Module  : kudzu_tcl.tcl
#         : An easy to use, extendable, event driven template engine for Tcl/Tk.
# Version : 1.0.0
# Require : Tcl 8.5 or better, TclOO
# License : MIT
# Author  : Andrew Friedl @ TriLogic Industries, LLC
#
package require TclOO

namespace eval kte {
    variable KudzuVersion           "1.0.0"
    variable PatternForTags         {\{\{[^\{\}]+\}\}}
    variable PatternForEndTags      "{{/"
    variable PatternForTermedTags   "/}}"
    variable PatternForFields       "\{\{="

    # Function to run a test case
    proc regexTest {regex input expected} {
        if {[regexp $regex $input match]} {
            set result "MATCH: $match"
        } else {
            set result "NO MATCH"
        }
        if {$result eq $expected} {
            puts " PASS: '$input' -> $result"
        } else {
            puts " FAIL: '$input' -> Expected '$expected', got '$result'"
        }
    }

    proc IsEndTag {value} {
        return [string match ${::kte::PatternForEndTags}* $value]
    }

    proc IsTermedTag {value} {
        return [string match *${::kte::PatternForTermedTags} $value]
    }

    proc IsFieldTag {value} {
        return [string match ${::kte::PatternForFields}* $value]
    }

    proc testAllRegex {} {

        # Testing Regex for Tags
        puts "\nTesting RegexForTags = '$::kte::PatternForTags'"
        regexTest $::kte::PatternForTags {{{tag content}}}         {MATCH: {{tag content}}}
        regexTest $::kte::PatternForTags {{{nested {tag}}}}        {NO MATCH}
        regexTest $::kte::PatternForTags {{{tag}}extra\}\}}        {MATCH: {{tag}}}
        regexTest $::kte::PatternForTags {No match here}           {NO MATCH}

        puts "\nCompleted Testing Regex"
    }

    proc stringToBool {value} {
        set value [string tolower $value]
        if { ($value eq true) || ($value eq 1) || ($value eq yes)} {return true}
        return false
    }

    #----------------------------------------------------------------------
    # String to escaped string mapping
    #----------------------------------------------------------------------
    set StringToEscapeMaping {
        "\\" \\\\
        "{" \{
        "}" \}
        "[" \[
        "]" \]
        "\"" \"
        "$" \$
        "\r" "\\r"
        "\n" "\\n"
        "\t" "\\t"
    }

    proc EscapeString {input} {
        # Apply the mapping StringToEscapeMaping
        return [string map $::kte::StringToEscapeMaping $input]
    }

    #----------------------------------------------------------------------
    # TagLibItem Class
    #----------------------------------------------------------------------
    oo::class create TagLibItem {
        variable tags libName libDesc libFile libFunc libVers

        constructor {} {
            my variable tags libName libDesc libFile libFunc libVers
            set tags [dict create]
            set libName ""
            set libDesc ""
            set libFile ""
            set libFunc ""
            set libVers "0.0"
        }

        method setTag {tag obj} {
            my variable tags
            set tag [string tolower $tag]
            dict unset tags $tag
            dict set tags $tag $obj
        }
        method getTag {tag} {
            my variable tags

            set tag [string tolower $tag]
            if {[dict exists $tags $tag]} {
                return [dict get $tags $tag]
            } else {
                return ""
            }
        }
        method libInit {sPath sName} {
            my variable libName libFile libFunc
            set libName [string toupper $sName]
            set libFile [file join $sPath "KudzuTagLib_${libName}.tcl"]
            set libFunc "::KudzuTagLib_${libName}::ImportTags"
        }
        method setTags {eng} {
            my variable tags
            foreach {key value} [dict get $tags] {
                set handler [$value new]
                $eng setHandler $key $handler
            }
        }
        method libImport {} {
            my variable libFile libFunc libName
            ::kte::LoadTagLibFile $libFile
            $libFunc [self]
        }
        method toString {} {
            my variable libName libFile libFunc
            return "libName: $libName\nlibFile: $libFile\nlibFunc: $libFunc"
        }
    }

    #----------------------------------------------------------------------
    # TagLib Class
    #----------------------------------------------------------------------
    oo::class create TagLib {
        variable tagLibs libPath libCurr

        constructor {} {
            variable tagLibs libPath libCurr
            set tagLibs [dict create]
            set libPath [list [pwd]]
            set libCurr ""
        }
        destructor {
            variable tagLibs
            dict for {name lib} $tagLibs {
                $lib destroy
            }
        }
        method libExists {libName} {
            my variable tagLibs
            set libName [string toupper $libName]
            return [dict exists $tagLibs $libName]
        }
        method libFind {libName} {
            my variable libPath
            set libName [string toupper $libName]
            foreach path $libPath {
                set fullPath [file join $path "KudzuTagLib_${libName}.tcl"]
                if {[file exists $fullPath]} {
                    return $path
                }
            }
            return ""
        }
        method libImport {libName} {
            my variable tagLibs libCurr
            set libName [string toupper $libName]

            if {[my libExists $libName]} {
                # ??? destroy the old and reimport ???
                return [dict get $tagLibs $libName]
            }

            set path [my libFind $libName]
            if {$path eq ""} {
                error "TagLib library not found $libName"
            }

            set libCurr [::kte::TagLibItem new]
            $libCurr libInit $path $libName
            dict unset tagLibs $libName
            dict set tagLibs $libName $libCurr
            $libCurr libImport
            return $libCurr
        }
        method libGet {libName} {
            my variable tagLibs
            set libName [string toupper $libName]
            return [dict get $tagLibs $libName]
        }
        method libSetTags {libName eng} {
            set lib [my libImport $libName]
            if {$lib eq ""} {
                return false
            }
            $lib setTags $eng
            return true
        }
        method libPathPush {sPath} {
            my variable libPath
            lappend libPath $sPath
        }
        method libPathPop {} {
            my variable libPath
            if {[llength $libPath] > 1} {
                set libPath [lrange $libPath 0 end-1]
            }
        }
        method setLibPath {sPath} {
            my variable libPath

            set libPath [list $sPath]
        }
    }

    #----------------------------------------------------------------------
    # TagLib Creation and Helper Procs
    #----------------------------------------------------------------------
    proc CreateTagLib {baseLibPath} {
        set lib [TagLib new]
        $lib setLibPath $baseLibPath
        return $lib
    }

    proc ReadTagLibFile {pluginFullPath} {
        set file [open $pluginFullPath r]
        set content [read $file]
        close $file
        return $content
    }

    proc LoadTagLibFile {pluginFile} {
        set source [::kte::ReadTagLibFile $pluginFile]
        eval $source
    }

    #----------------------------------------------------------------------
    # Tag Handler Base Class - KTHBase
    #----------------------------------------------------------------------
    oo::class create KTHBase {
        
        method handleTag {node} {
            error "handleTag not implemented in subclass"
        }
        method appendError {node message} {
            $node appendError $message
        }
        method getParam {node index} {
            return [$node getParamItem $index]
        }
        method getParamCount {node} {
            return [$node getParamCount]
        }
    }

    #----------------------------------------------------------------------
    # TemplateNode Class
    #----------------------------------------------------------------------
    oo::class create TemplateNode {
        # Instance variables
        variable iid
        variable mStartTag mStopTag mContent
        variable mEngine mNodes mParams

        constructor {} {
            my variable iid mStartTag mStopTag mContent
            my variable mNodes mParams mEngine
            set iid ""
            set mStartTag ""
            set mStopTag ""
            set mContent ""
            set mNodes [list]
            set mParams [list]
            set mEngine ""
        }
        destructor {
            my variable mNodes
            foreach node $mNodes {
                $node destroy
            }
        }
        method toString {} {
            my variable iid mStartTag mStopTag mContent
            my variable mNodes mParams mEngine
            return "\nTemplateNode: [self]\n IID: $iid \n StartTag: $mStartTag \n StopTag: $mStopTag\n Params: {[join $mParams ", "]}\n Content: $mContent \n Engine: $mEngine \n SubNodes: [llength $mNodes]"
        }
        
        method getEngine {} {
            my variable mEngine
            return $mEngine
        }
        method setEngine {engine} {
            my variable mEngine
            set mEngine $engine
            foreach node $mNodes {
                $node setEngine $engine
            }
        }
        method getID {} {
            my variable iid
            return $iid
        }
        method setID {value} {
            my variable iid
            set iid [string tolower $value]
        }
        method getStartTag {} {
            my variable mStartTag
            return $mStartTag
        }
        method setStartTag {value} {
            my variable mStartTag
            set mStartTag [string tolower $value]
        }
        method getStopTag {} {
            my variable mStopTag
            return $mStopTag
        }
        method setStopTag {value} {
            my variable mStopTag
            set mStopTag [string tolower $value]
        }
        method getContent {} {
            my variable mContent
            return $mContent
        }
        method setContent {value} {
            my variable mContent
            set mContent $value
        }
        method getNodeItem {index} {
            my variable mNodes
            return [lindex $mNodes $index]
        }
        method getNodeCount {} {
            my variable mNodes
            return [llength $mNodes]
        }
        method nodeAppend {node} {
            my variable mNodes
            lappend mNodes $node
        }
        method getParamCount {} {
            my variable mParams
            return [llength $mParams]
        }
        method getParamItem {index} {
            my variable mParams
            return [lindex $mParams $index]
        }
        method paramAdd {value} {
            my variable mParams
            lappend mParams $value
        }

        method evalTagID {} {
            my variable iid mEngine
            if {[$mEngine hasHandler $iid]} {
                set handler [$mEngine getHandler $iid]
                $handler handleTag [self]
            }
        }
        method evalParamString {param} {
            my variable mEngine
            if {[$mEngine hasValue $param]} {
                return [$mEngine getValue $param]
            } else {
                return [eval $param]
            }
        }
        method evalParamObject {param} {
            my variable mEngine
            if {[$mEngine hasValue $param]} {
                return [$mEngine getObjectValue $param]
            } else {
                return [eval $param]
            }
        }
        method evalNode {} {
            my variable iid mStartTag mEndTag mEngine

            if {$iid eq "" || $iid eq "_root"} {
                $mEngine contentAppend $mContent
                my evalNodes
            } else {
                my evalTagID
                #catch {[my evalTagID]} errMsg
                #if {$errMsg ne ""} {
                #    $mEngine contentAppend $errMsg
                #}
            }

        }
        method evalNodeID {nodeID} {
            set node [my locateNode $nodeID]
            if {$node eq ""} {
                return
            }
            $node evalNodes
        }
        method evalNodes {} {
            my variable mNodes
            foreach node $mNodes {
                $node evalNode
            }
        }

        # Stack Operations
        method stackPush {} {
            my variable mEngine
            $mEngine contentPush
        }
        method stackPop {} {
            my variable mEngine
            $mEngine contentAppend [$mEngine contentPop]
        }

        # Content Appending
        method appendText {text} {
            set node [::kte::TemplateNode new]
            $node setContent $text
            my nodeAppend $node
        }
        method appendError {msg} {
            my variable iid
            my appendContent "\nError:$iid\n"
            if {$msg ne ""} {
                my appendContent "  $msg\n"
            }
        }
        method appendContent {content} {
            my variable mEngine
            $mEngine contentAppend $content
        }
        method appendTagError {msg} {
            my stackPush
            my appendError $msg
            my stackPop
        }

        # Locate a node with a specific ID
        method locateNode {nodeID} {
            my variable mNodes
            set id [string tolower $nodeID]
            foreach node $mNodes {
                if {[$node getID] eq $id} {
                    return $node
                }
            }
            return ""
        }
    }

    #----------------------------------------------------------------------
    # TemplateCompiler Class
    #----------------------------------------------------------------------
    oo::class create TemplateCompiler {
        # Instance variables
        variable mParseLevel mParseStack
        variable mWriter

        # Constructor
        constructor {} {
            my variable mParseLevel mParseStack
            my variable mWriter
            my initParseStack
            set mWriter ""
        }

        # The object's toString method
        method toString {} {
            puts "nothing here yet"
        }

        # Initialize the parse stack
        method initParseStack {} {
            my variable mParseStack mParseLevel

            set mParseStack [list [::kte::TemplateNode new]]
            [lindex $mParseStack 0] setEngine [self]
            [lindex $mParseStack 0] setID "_root"

            set mParseLevel 0
        }

        # Getters and Setters
        method getWriter {} {
            my variable mWriter
            return $mWriter
        }
        method setWriter {writer} {
            my variable mWriter
            set mWriter $writer
        }

        # Parse Stack Operations
        method parsePush {value} {
            my variable mParseLevel mParseStack
            incr mParseLevel
            lappend mParseStack $value
        }
        method parsePop {} {
            my variable mParseLevel mParseStack
            set value [lindex $mParseStack end]
            set mParseStack [lrange $mParseStack 0 end-1]
            incr mParseLevel -1
            return $value
        }
        method parsePeek {} {
            my variable mParseStack
            return [lindex $mParseStack end]
        }
        method getParseLevel {} {
            my variable mParseLevel
            return $mParseLevel
        }
        
        method parseFile {fileName} {
            if {![file exists $fileName]} {
                error "File not found: $fileName"
            }
            set fileContent [read [open $fileName]]
            return [my parseString $fileContent]
        }
        method parseString {template} {
            my variable mParseStack
            my initParseStack    
            set pattern $::kte::PatternForTags
            set start 0
            set preText {}
            set tagText {}
            set matches [regexp -all -inline $pattern $template]
            while {[regexp -indices -start $start $pattern $template matchIdx]} {
                set matchStart [lindex $matchIdx 0]
                set matchEnd [lindex $matchIdx 1]
                if {$matchStart > $start} {
                    set preText [string range $template $start [expr {$matchStart - 1}]]
                    [my parsePeek] appendText $preText
                }
                set tagText [string range $template $matchStart $matchEnd]
                my handleTagMatch $tagText
                set start [expr {$matchEnd + 1}]
            }
            if {$start < [string length $template]} {
                set postText [string range $template $start end]
                [my parsePeek] appendText $postText
            }
            set node [my parsePeek]
            set nodeID [$node getID]
            if {[string compare $nodeID _root] != 0} {
                error "Mismatched node: '$nodeID', [$node getStartTag]"
            }
            return [lindex $mParseStack 0]
        }
        method handleTagMatch {tag} {
            if {[::kte::IsEndTag $tag]} {
                my parseEndTag $tag
            } elseif {[kte::IsFieldTag $tag]} {
                my parseFieldTag $tag
            } elseif {[::kte::IsTermedTag $tag]} {
                my parseTermedTag $tag
            } else {
                my parseBeginTag $tag
            }
        }
        method parseTagProperties {tag node setID} {
            set temp [string range $tag 2 end-2]
            if {[string index $temp 0] eq "/"} {
                set isStopTag true
                set temp [string range $temp 1 end]
            } elseif {[string index $temp end] eq "/"} {
                set isStopTag true
                set temp [string range $temp 0 end-1]
            }
            set temp [string trim $temp]
            set parts [split $temp "|"]
            set iid [string trim [lindex $parts 0]]
            $node setID $iid
            if { [::kte::IsEndTag $tag] } {
                $node setEndTag $tag
            } elseif { [::kte::IsTermedTag $tag] } {
                $node setStartTag $tag
                $node setStopTag  $tag
            } else {
                $node setStartTag $tag
            }
            foreach part [lrange $parts 1 end] {
                $node paramAdd [string trim $part]
            }
        }
        method parseBeginTag {tag} {
            set node [::kte::TemplateNode new]
            $node setEngine [self]
            my parseTagProperties $tag $node true
            my parsePush $node
        }
        method parseEndTag {tag} {
            set iid [string tolower [string trim [string range $tag 3 end-2]]]

            # The TOS node must match by iid and if not there's an error.
            set tosNode [my parsePeek]
            if {[string compare [$tosNode getID] $iid] != 0} {
                throw "Unmatched tag: $iid [$tosNode getStartTag]"
            } elseif {[$tosNode getStopTag] ne ""} {
                # Special case where if the node with iid matches the
                # TOS iid but the previous tag was a self termed tag.
                throw "Unmatched tag: $iid [$tosNode getStartTag]"
            }

            # pop the current node from the top of the parsing stack
            # because the current node terminates it and belongs to it
            set node [my parsePop]
            $node setStopTag $tag
            [my parsePeek] nodeAppend $node
        }

        method parseFieldTag {tag} {
            set node [::kte::TemplateNode new]
            $node setEngine [self]
            set temp [string range $tag 3 end-2]
            set temp [string trim $temp]
            $node setID "="
            $node setContent    $temp
            $node setStartTag   $tag
            $node setStopTag    "="
            [my parsePeek] nodeAppend $node
        }

        method parseTermedTag {tag} {
            set node [::kte::TemplateNode new]
            $node setEngine [self]
            my parseTagProperties $tag $node false
            [my parsePeek] nodeAppend $node
        }

        method writeOutput {content} {
            my variable mWriter
            
            if {$mWriter eq ""} {
                puts $content
            } else {
                $mWriter write $content
            }
        }

        method dString {count rep} {
            return [string repeat $rep $count]
        }
    }

    #----------------------------------------------------------------------
    # Standard Tag Handlers (KTH Classes)
    #----------------------------------------------------------------------
    oo::class create KTHFlush {
        superclass KTHBase

        method handleTag {vNode} {
            [$vNode getEngine] contentFlush
        }
    }

    oo::class create KTHImport {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "libName[|libName2]*"
                return
            }

            set engine [$vNode getEngine]
            if {[$engine hasTagLib]} {
                
                set tagLib [$engine getTagLib]

                for {set idx 0} {$idx < [$vNode getParamCount]} {incr idx} {
                    set name [$vNode getParamItem $idx]
                    puts "Importing Library: $name"

                    $tagLib libImport $name
                    $tagLib libSetTags $name $engine
                }
            } else {
                error "no tag libary assigned"
            }            
        }
    }

    oo::class create KTHIgnore {
        superclass KTHBase

        method handleTag {vNode} {
            # No operation
        }
    }

    oo::class create KTHValue {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "value_id"
                return
            }

            if {[$vNode getParamItem 1] eq ""} {
                return
            }

            $vNode stackPush
            catch {
                [$vNode getEngine] contentAppend [$vNode evalParamString [$vNode getParamItem 1]]
            } errMsg
            $vNode stackPop
        }
    }

    oo::class create KTHIIf {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 3} {
                $vNode appendTagError "value_id|true_id|false_id"
                return
            }

            $vNode stackPush
            if {![::kte::stringToBool [$vNode evalParamString [$vNode getParamItem 0]]]} {
                [$vNode getEngine] contentAppend [$vNode evalParamString [$vNode getParamItem 2]]
            } else {
                [$vNode getEngine] contentAppend [$vNode evalParamString [$vNode getParamItem 3]]
            }
            $vNode stackPop
        }
    }

    oo::class create KTHIfTrue {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "iftrue|variable"
                return
            }

            if {![::kte::stringToBool [$vNode evalParamString [$vNode getParamItem 0]]]} {
                return
            }

            $vNode stackPush
            $vNode evalNodes
            $vNode stackPop
        }
    }

    oo::class create KTHIfFalse {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "value_id"
                return
            }

            if {[::kte::stringToBool [$vNode evalParamString [$vNode getParamItem 0]]]} {
                return
            }

            $vNode stackPush
            $vNode evalNodes
            $vNode stackPop
        }
    }

    oo::class create KTHIfThen {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "value_id"
                return
            }

            if {[::kte::stringToBool [$vNode evalParamString [$vNode getParamItem 0]]]} {
                my evalNode $vNode "then"
            } else {
                my evalNode $vNode "else"
            }
        }

        method evalNode {vNode sNode} {
            set node [$vNode locateNode $sNode]
            if {$node eq {}} {
                return
            }
            $node stackPush
            $node evalNodes
            $node stackPop
        }
    }

    oo::class create KTHCase {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendTagError "value_id"
                return
            }
            set varName [$vNode getParamItem 0]
            set caseName [$vNode evalParamString [$vNode getParamItem 0]]
            my evalCase $vNode $caseName
        }

        method evalCase {vNode sNode} {
            set node [$vNode locateNode $sNode]
            if {$node eq ""} {
                set node [$vNode locateNode "else"]
            }
            if {$node eq ""} {
                return
            }
            $node stackPush
            $node evalNodes
            $node stackPop
        }
    }

    oo::class create KTHDecr {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendError "value_id|?initial?"
                return
            }
            set engine [$vNode getEngine]
            set valName [$vNode getParamItem 0]
            set curValue 0
            if {[$vNode getParamCount] > 1} {
                set curValue [$vNode getParamItem 1]
            } elseif {[$engine hasValue $valName]} {
                set curValue [expr [$engine getValue $valName] - 1]
            }
            $engine setValue $valName $curValue
        }
    }

    oo::class create KTHIncr {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 1} {
                $vNode appendError "value_id|?initial?"
                return
            }
            set engine [$vNode getEngine]
            set valName [$vNode getParamItem 0]
            set curValue 0
            if {[$vNode getParamCount] > 1} {
                set curValue [$vNode getParamItem 1]
            } elseif {[$engine hasValue $valName]} {
                set curValue [expr [$engine getValue $valName] + 1]
            }
            $engine setValue $valName $curValue
        }
    }

    oo::class create KKTHImport {
        superclass ::kte::KTHBase

        method handleTag {node} {
            set eng [$node getEngine]

            $node stackPush
            $node evalNodes
            $eng  setContent [string trim [$eng getContent]]
            $node stackPop;
        }
    }

    oo::class create KTHSetValue {
        superclass KTHBase

        method handleTag {vNode} {
            set count [$vNode getParamCount] 
            if {$count < 1} {
                $vNode appendError "|value_id=value|..."
                return
            }
            set engine [$vNode getEngine]
            for {set idx 0} {$idx < $count} {incr idx} {
                set param [$vNode getParamItem $idx]
                set pair [split $param "="]
                set valName [string trim [lindex $pair 0]]
                set valText {}
                if {[llength $pair] > 1} {
                    set valText [string trim [lindex $pair 1]]
                }
                $engine setValue $valName $valText
            }
        }
    }

    oo::class create KTHUnSetValue {
        superclass KTHBase

        method handleTag {vNode} {
            set count [$vNode getParamCount]
            if {$count < 1} {
                $vNode appendError "value_id|..."
                return
            }
            set engine [$vNode getEngine]
            for {set idx 0} {$idx < $count} {incr idx} {
                set valName [$vNode getParamItem $idx]
                $engine unsetValue $valName
            }
        }
    }

    oo::class create KTHEqValue {
        superclass KTHBase

        method handleTag {vNode} {
            set engine [$vNode getEngine]
            set content [$vNode getContent]
            set name $content
            set value "{{=$name}}"

            if {[$engine hasValue $name]} {
                set value [$engine getValue $name]
            }

            $vNode  stackPush
            $engine setContent $value
            $vNode  stackPop
        }
    }

    oo::class create KTHCycle {
        superclass KTHBase

        method handleTag {vNode} {
            if {[$vNode getParamCount] < 3} {
                $vNode appendError "value_id|Alt1|Alt2..."
                return
            }
            set valName [$vNode getParamItem 0]
            set altValues [list]
            for {set idx 1} {$idx < [$vNode getParamCount]} {incr idx} {
                lappend altValues [$vNode getParamItem $idx]
            }
            set engine [$vNode getEngine]
            if {[$engine hasValue $valName]} {
                set curValue [$engine getValue $valName]
                set idx [lsearch -exact $altValues $curValue]
                if {$idx == -1 || $idx == [expr {[llength $altValues] - 1}]} {
                    set nextValue [lindex $altValues 0]
                } else {
                    set nextValue [lindex $altValues [expr {$idx + 1}]]
                }
            } else {
                set nextValue [lindex $altValues 0]
            }
            $engine setValue $valName $nextValue
        }
    }

    #----------------------------------------------------------------------
    # OutputWriter Classes
    #----------------------------------------------------------------------    
    oo::class create OutputToNullWriter {
        method writeOutput {text} {
        }
    }
    oo::class create OutputToPutsWriter {
        method writeOutput {text} {
            puts $text
        }
    }
    oo::class create OutputToStringWriter {
        variable output
        constructor {} {
            my variable output
            set output ""
        }
        method writeOutput {text} {
            my variable output
            set output [string cat $output $text]
        }
        method toString {} {
            my variable output
            return $output
        }
    }
    oo::class create OutputToParentWriter {
        variable engine
        constructor {parent} {
            my variable engine
            set engine $parent
        }
        method writeOutput {text} {
            my variable engine
            $engine writeOutput $text
        }
    }


    #----------------------------------------------------------------------
    # TemplateEngine Class
    #----------------------------------------------------------------------
    oo::class create TemplateEngine {
        # Instance variables
        variable mRunStack mRunLevel
        variable mNodeTree
        variable mHandlers mValues
        variable mFactory
        variable mWriter
        variable mTagLib

        # Constructor
        constructor {writer} {
            my variable mHandlers mValues mWriter
            my variable mRunStack mRunLevel mTagLib

            set mHandlers [dict create]
            set mValues [dict create]
            set mRunStack [list ""]
            set mRunLevel 0
            set mTagLib {}

            if {$writer eq ""} {
                puts {WRITER = kte::OutputToStringWriter}
                set mWriter [kte::OutputToStringWriter new]
            } else {
                set mWriter $writer
            }

            dict set mValues kudzuversion $::kte::KudzuVersion
        }

        # Install default handlers
        method installHandlers {} {
            my variable mHandlers

            # free any existing handlers
            dict for {name handler} $mHandlers {
                $handler destroy
                dict remove $mHandlers $name
            }

            my setHandler "Case"        [::kte::KTHCase new]
            my setHandler "Cycle"       [::kte::KTHCycle new]
            my setHandler "Decr"        [::kte::KTHDecr new]
            my setHandler "Flush"       [::kte::KTHFlush new]
            my setHandler "IIf"         [::kte::KTHIIf new]
            my setHandler "If"          [::kte::KTHIfThen new]
            my setHandler "IfTrue"      [::kte::KTHIfTrue new]
            my setHandler "IfFalse"     [::kte::KTHIfFalse new]
            my setHandler "Ignore"      [::kte::KTHIgnore new]
            my setHandler "Import"      [::kte::KTHImport new]
            my setHandler "Incr"        [::kte::KTHIncr new]
            my setHandler "="           [::kte::KTHEqValue new]
            my setHandler "SetValue"    [::kte::KTHSetValue new]
            my setHandler "UnSetValue"  [::kte::KTHUnSetValue new]
        }

        # Reset class state
        method classReset {} {
            my variable mNodeTree mRunStack mRunLevel

            set mNodeTree [kte::TemplateNode new]
            $mNodeTree setEngine [self]
            $mNodeTree setContent "No Content"

            set mRunStack [list ""]
            set mRunLevel 0

            set mValues [dict create]
            my setValue KudzuVersion $::kte::KudzuVersion

        }

        # Getters and setters
        method setWriter {writer} {
            my variable mWriter
            if {$writer eq {}} {
            } else {
                set mWriter $writer
            }
        }
        method getWriter {} {
            my variable mWriter
            return $mWriter
        }

        # Tag Library Support
        method setTagLib {lib} {
            my variable mTagLib
            if {$lib eq {}} {
                if {$mTagLib ne {}} {
                    $mTagLib destroy
                }
            }
            set mTagLib $lib
        }
        method getTagLib {} {
            my variable mTagLib
            return $mTagLib
        }
        method hasTagLib {} {
            my variable mTagLib
            if {$mTagLib eq {}} {
                return false
            }
            return true
        }

        method getFactory {} {
            my variable mFactory
            return $mFactory
        }
        method setFactory {factory} {
            my variable mFactory
            set mFactory $factory
        }
        method hasFactory {} {
            my variable mFactory
            return [expr $mFactory ne {}]
        }

        # Handler dictionary operations
        method hasHandler {name} {
            my variable mHandlers
            return [dict exists $mHandlers [string tolower $name]]
        }
        method getHandler {name} {
            my variable mHandlers
            return [dict get $mHandlers [string tolower $name]]
        }
        method setHandler {name handler} {
            my variable mHandlers
            dict unset mHandlers [string tolower $name]
            dict set mHandlers [string tolower $name] $handler
        }
        method unSetHandler {name} {
            my variable mHandlers
            set key [string tolower $name]
            if {dict exists $mHandlers $key} {
                set obj [dict get $mHandlers $key]
                $obj destroy
                dict unset mHandlers $key
            }
        }

        # Value dictionary operations
        method hasValue {name} {
            my variable mValues
            return [dict exists $mValues [string tolower $name]]
        }
        method getValue {name} {
            my variable mValues
            return [dict get $mValues [string tolower $name]]
        }
        method setValue {name value} {
            my variable mValues
            dict unset mValues [string tolower $name]
            dict set mValues [string tolower $name] $value
        }
        method unsetValue {name} {
            my variable mValues
            dict unset mValues [string tolower $name]
        }

        # Parsing methods
        method parseFile {fileName} {
            if {![file exists $fileName]} { 
                error "File not found: $fileName"
            }
            set content [read [open $fileName]]
            return [my parseString $content]
        }
        method parseString {template} {
            my variable mNodeTree mWriter
            set compiler [kte::TemplateCompiler new]
            $compiler setWriter $mWriter
            my classReset
            set mNodeTree [$compiler parseString $template]
            $mNodeTree setEngine [self]
        }
        method evalTemplate {} {
            my variable mNodeTree mRunStack
            $mNodeTree evalNode
            my writeOutput [lindex $mRunStack 0]
        }

        # Content management methods
        method getContent {} {
            my variable mRunStack mRunLevel
            return [lindex $mRunStack $mRunLevel]
        }
        method setContent {value} {
            my variable mRunStack mRunLevel
            set mRunStack [lreplace $mRunStack $mRunLevel $mRunLevel $value]
        }
        method contentLevel {} {
            my variable mRunLevel
            return $mRunLevel
        }
        method contentPush {} {
            my variable mRunStack mRunLevel
            incr mRunLevel
            lappend mRunStack ""
        }
        method contentPop {} {
            my variable mRunStack mRunLevel
            set content [lindex $mRunStack end]
            set mRunStack [lrange $mRunStack 0 end-1]
            incr mRunLevel -1
            return $content
        }
        method contentAppend {text} {
            my variable mRunStack mRunLevel
            lset mRunStack $mRunLevel [lindex $mRunStack $mRunLevel]$text
        }
        method contentFlush {} {
            my variable mRunStack
            foreach idx $mRunStack {
                my writeOutput $idx
            }
            set mRunStack [list ""]
        }

        # Output methods
        method writeOutput {content} {
            my variable mWriter
            $mWriter writeOutput $content
        } 

        method initialize {} {
            my installHandlers
            my setValue KudzuVersion $::kteKudzuVersion
            my classReset
        }
    }

    #----------------------------------------------------------------------
    # TemplateEngine Creation Procs
    #----------------------------------------------------------------------
    proc CreateEngine {writer} {
        set engine [::kte::TemplateEngine new $writer]
        $engine installHandlers
        return $engine
    }

    proc CreateCompiler {} {
        set compiler [::kte::TemplateCompiler new]
        return $compiler
    }

    proc CreateChildEngine {parent} {
        set writer [::kte::OutputToParentWriter new $parent]
        set childEngine [kte::CreateEngine $writer]
        $childEngine setParent $node
        return $childEngine
    }
}
