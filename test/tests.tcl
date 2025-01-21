#
# Module  : tests.tcl
#         : a test scipt for KudzuTCL
# Version : 1.0.0
# Require : Tcl 8.5 or better, TclOO, KudzuTCL
# License : MIT
# Author  : Andrew Friedl @ TriLogic Industries, LLC

#
# Code to run a regex test cases
#
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

proc testAllRegex {} {

    # Testing Regex for Tags
    puts "\nTesting RegexForTags = '$::kte::PatternForTags'"
    regexTest $::kte::PatternForTags {{{tag content}}}         {MATCH: {{tag content}}}
    regexTest $::kte::PatternForTags {{{nested {tag}}}}        {NO MATCH}
    regexTest $::kte::PatternForTags {{{tag}}extra\}\}}        {MATCH: {{tag}}}
    regexTest $::kte::PatternForTags {No match here}           {NO MATCH}

    puts "\nCompleted Testing Regex"
}

#
# set the current working path
#
set curPath [pwd]
puts "current path is: $curPath"

#
# set the path to the kudzu tcl source nd source it
#
set scrPath "$curPath/src"
puts "script path is: $scrPath"
source "$scrPath/kudzu_tcl.tcl"

#
# set the libary path for the libraries
#
set libPath "$curPath/src"
puts "libPath is : $libPath"
set tagLib [::kte::CreateTagLib $libPath]

#
# set the template path
#
set tplPath "$curPath/src"
puts "tplPath is : $tplPath"

#
# Create a Template Engine
#
set engine [kte::CreateEngine [kte::OutputToPutsWriter new]]

#
# Add tags from the string tag library to the engine
#
$tagLib libSetTags "string" $engine

#
# Install string tag library into the current engine
#
puts "\nSET engine's tagLib value to $tagLib"
$engine setTagLib $tagLib

#
# Execute a template from the template
#
puts "\nTest executing a template that exists in file form"
puts {-----------------------------------------------------------------------}
$engine parseFile "$tplPath/test.tpl"
$engine setValue keyword BOOYAH
$engine setValue trueBool true
$engine setValue falseBool false
$engine evalTemplate

$tagLib destroy
puts done.
