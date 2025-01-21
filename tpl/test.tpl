A Test Template for KudzuTCL:

Testing {{=}}
-----------------------------------------------------------------------
trueBool            : {{= trueBool }},
falseBool           : {{= falseBool }},
KudzuVersion        : This is KudzuTPL Version {{= KudzuVersion }}
-----------------------------------------------------------------------
Testing IfTrue:

IfTrue  on trueBool : {{iftrue | trueBool }}TRUE{{/iftrue}}
IfFalse on trueBool : {{iffalse | trueBool}}TRUE{{/iffalse}}
-----------------------------------------------------------------------
Testing IfFalse:

IfFalse on falseBool: {{iftrue | falseBool }}FALSE{{/iftrue}}
IfFalse on falseBool: {{iffalse | falseBool}}FALSE{{/iffalse}}
-----------------------------------------------------------------------
Testing If-Then-Else with trueBool

{{ if| trueBool }}
{{then}} IT WAS TRUE. {{/then}}
{{else}} IT WAS FALSE - ERROR {{/else}}
{{/ if }}

Testing If-Then-Else with falseBool

{{ if | falseBool }}
{{then}} IT WAS TRUE - ERROR {{/then}}
{{else}} IT WAS FALSE. {{/else}}
{{/if}}
-----------------------------------------------------------------------
Testing Import Tag: {{import|string/}}

Testing Imported STRING Library:

UCASE: {{ucase}}This text should be all upper case.{{/ucase}}
LCASE: {{lcase}}This text should be all lower case.{{/lcase}}
LTRIM: |{{ltrim}}          Text trimmed left.{{/ltrim}}|
RTRIM: |{{rtrim}}Text trimmed right.         {{/rtrim}}|
TRIM : |{{trim}}     Text trimmed.     {{/trim}}|
-----------------------------------------------------------------------
Testing Embedded Tags:

TAGS: |{{trim}}    Result should be trimmed {{ucase}}upper case{{/ucase}} and {{lcase}}LOWER CASE{{/lcase}} text.    {{/trim}}|
-----------------------------------------------------------------------
Testing Ignore Tag: expect: 1 2 3 4 5 8 9 10 

Ignore: 1 2 3 4 5{{ignore}} 6 7{{/ignore}} 8 9 10
-----------------------------------------------------------------------
Testing Cycle Tag:

Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
Cycle value is: {{cycle|cycleValue|one|two|three/}}{{=cycleValue}}
-----------------------------------------------------------------------
Testing SetValue && UnSetValue:

The values of {abc, xyz} are: {{setvalue | abc=123 | xyz=pdq /}} {{{=abc}}, {{=xyz}}}
The values of {abc, xyz} are: {{unsetvalue | xyz /}} {{{=abc}}, {{=xyz}}}
-----------------------------------------------------------------------
Testing Incr && Decr:{{ setvalue| incrVal 1 | decrVal 100 /}} {{{=incrVal}}, {{=decrVal}}}

The values of {incrVal, decrVal} are:{{ incr | incrVal | 25 /}}{{decr | decrVal | 25 /}} {{{=incrVal}}, {{=decrVal}}}
The values of {incrVal, decrVal} are:{{ incr | incrVal /}}{{decr | decrVal /}} {{{=incrVal}}, {{=decrVal}}}
The values of {incrVal, decrVal} are:{{ incr | incrVal /}}{{decr | decrVal /}} {{{=incrVal}}, {{=decrVal}}}
-----------------------------------------------------------------------
Testing Case: expect "caseValue = 'def'"
{{ setvalue | caseValue=def /}}
{{ case | caseValue }}{{abc}}caseValue = abc{{/abc}}
{{def}}caseValue = def{{/def}}{{else}}caseValue = '{{=caseValue}}{{/else}}'
{{/ case }}
