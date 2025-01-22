# KudzuTCL
An easy to use, extensible, event driven, object-oriented template engine for Tcl/Tk.

A template for KudzuTCL contains tags and content.  Tags are markup that direct the template engine to perform some special function like repitition or conditional inclusion of content.  Some tags contain inner content, some do not.  Some tags support inner content that allows the inclusion of other tags. Other tags like 'If' and 'Case' only support special tags within their immediate inner content.

Tags are always  written in one the following forms:
```
{{ IfTrue | valName }} some inner content {{/ IfTrue }} - a being tag, inner content and an end tag
{{ decrVal | valName /}} - a self terminated tag that doesnt respec inner content
{{ decrVal | valName }} inner content used a a comment that will be ignored {{/ decrVal }}
{{= valName }} special tag to include values within content and inner content
```

By default the names of tags are case insensitive as are parameter names passed to the tags.  It's possible to write your own tags that are not.  Also not that whitespace within the tags is ignored.

With respect to parameters there are some tags that expect parameters to be passed.  This is done by appending a pipe delimited list after the tag name.  The 'Cycle' tag is a good example of this. It expects the name of a value to use and then a list of values to cycle through.  Each execution of cycle retrieves the existing value from the template engine and replaces it with the next value on the list.
```
{{ cycle | cycleValue | one | two | three /}}
```

Value substition tags:  This tag replaces itself with whatever value is assigned to the engine's values collection for the name specified. It is case insensitive.
```
trueBool            : {{= trueBool }},
falseBool           : {{= falseBool }},
KudzuVersion        : This is KudzuTPL Version {{= KudzuVersion }}
```

Conditional content tags 'IfTrue' and 'IfFalse' are examples of tags with inner content. Their inner content can contain other tags.
```
IfTrue  on trueBool : {{iftrue | trueBool }}TRUE{{/iftrue}}
IfFalse on trueBool : {{iffalse | trueBool}}TRUE{{/iffalse}}
```

The 'Ignore' tag ignores all of its inner content. It can be used to comment out blocks of template or to include commentsin your template.
```
{{ignore}}
Th content between the begin and end tags will be ignored as will the tags themselves.
{{/ignore}}
```

The 'Incr' and 'Decr' tags are used to increment and decrement values within the
template engines values collection.  Thay are also examples of tags that do not require 
an end tag (can self terminate). The following code increments the incrVal and decrements
the decrVal value in the template engines values collection.  Like most self terminating tags
you could not self terminate this tag and include inner content that would be ignored.
```
{{ incr | incrVal | 25 /}}
{{ decr | decrVal | 25 /}}
{{ decr | decrVal | 25 }} this content would be ignored {{/ decr }}
```

The 'Cycle' tag is used to cycle a variables through a list of values. It is also an
example of a tag that can self terminate. It ignores inner content.
```
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
```

The 'If' tag is a more complex tag for the conditional inclusion of content.  This tag expects one parameter that is the name of the value to evaluate for boolean true or false value.  If the corresponding value evaluates to true the inner 'Then' tag and it's inner content will be evaluated otherwise the inner 'Else' tag and it's inner content will be evaluated.  You can include other markup tags in the 'Then' and 'Else' tags.
```
{{ if | falseBool }}
{{then}} IT WAS TRUE - ERROR {{/then}}
{{else}} IT WAS FALSE. {{/else}}
{{/if}}
```

The 'Case' tag is an even more complex tag for condition content.  Like the 'If' tag it expects a value name as its first parameter.  This value is retrieved from the template engine's values collection and each child tag is matched to the value.  If the name of the tag matches the value then that tag and its inner content is evaluated.  If no tag matches the 'Else' tag (if present) is evaluated.  An example of 'Case would be.
```
{{ setvalue | caseValue=def /}}
{{ case | caseValue }}{{abc}}caseValue = abc{{/abc}}
{{def}}caseValue = def{{/def}}{{else}}caseValue = '{{=caseValue}}{{/else}}'
{{/ case }}
```

Did you notice the 'SetValue' tag was slipped in when we were discussing the 'Case' tag?  This tag is useful for setting values in the template engine's values collection.  It accepts the name of the value and the actual value to be set.  There is a corresponding 'UnsetValue' tag that removes a value from the template engine's values collection.
```
{{ setvalue | caseValue=def /}}
```

There are 14 standard tags recognized by the template engine including the {{= }} tag which has its own format:
- Case
- Cycle
- Decr
- Flush
- Iif
- If
- IfTrue
- IfFalse
- Ignore
- Import
- Incr
- SetValue
- UnsetValue

What's that 'Import' tag do? The template engine is very easy to extend and it supports a libary mechanism to allow extensions to be written in specially coded library files.  The 'Import' tag allows you to import these libaries on an 'as needed' basis - dynamically.  If your Tcl code properly sets up a libary manager and assigns it to the template engine you can import libaries and use the custom tags they contain all from the template.  th following code reates a template libary, set the pathing and applies it to a template engine:
```
set curPath [pwd]
puts "current path is: $curPath"

set libPath "$curPath/src"
puts "libPath is : $libPath"

set tagLib [::kte::CreateTagLib $libPath]
set engine [kte::CreateEngine [kte::OutputToPutsWriter new]]
$tagLib libSetTags "string" $engine
```

The previous code references a tag libary named 'string'.  That tag libary is written as an example of how to write tag handles and libraries of tag handlers.  The 'string' libary includes custom tag handlers for tags named { 'ucase', 'lcase', 'ltrim', 'rtrim', 'trim'} which do pretty much what you'd expect them to.  You can find the code file for the 'string' libary in the lib folder.

Custom tag handlers don't have to be in libaries. They can be defined in your Tcl code and aded to a template engine when needed.  A good example of a customer tag handler would be a specialized tag to query a database, then repeat content over each record from the database while setting values from each record into the values collection of the engine.

Template evaluation:  In KudzuTCl a template is evaluated as written.  Substitution and tag evaluation take place based on how the template is written.  So if you adhere to the engines callback model it's possible to move large blocks of your template without ever needing to change the Tcl code that supports it.
