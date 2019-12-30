# ml-snippetting

Custom MarkLogic snippeting functions

## Install

Installation depends on the [MarkLogic Package Manager](https://github.com/joemfb/mlpm):

```
$ mlpm install ml-snippeting --save
$ mlpm deploy
```

## doc-snippet

A snippeting function that concatenates the character data of the entire document to one text node before applying the usual snippeting. This allows search matches to show more textual context on data-like documents.

Take your REST api search options, and look for the `transform-result` section, which could look like this:

```xml
  <transform-results apply="snippet">
    <preferred-elements>
      <element ns="" name="body"/>
    </preferred-elements>
    <max-matches>1</max-matches>
    <max-snippet-chars>150</max-snippet-chars>
    <per-match-tokens>20</per-match-tokens>
  </transform-results>
```

Just change the first line of it as follows:

```xml
  <transform-results apply="snippet" ns="http://marklogic.com/doc-snippet" at="/ext/mlpm_modules/ml-snippeting/doc-snippet.xqy">
    <preferred-elements>
      <element ns="" name="body"/>
    </preferred-elements>
    <max-matches>1</max-matches>
    <max-snippet-chars>150</max-snippet-chars>
    <per-match-tokens>20</per-match-tokens>
  </transform-results>
```

Note: `preferred-elements` will effectively be ignored. You can omit that.

Note also: Flattening the document would cause range- and value-queries, to no longer match and giving no highlights. To counteract this snippeting adds a word-query for all values. That might highlight too much, but better than nothing.

## exclude-snippet

A snippeting function that excludes elements or JSON properties by name. Uses a new `excluded-matches` configuration element that takes the same configuration as `preferred-elements`. (An `excluded-elements` config element is also available; it only works with XML elements).

All other `transform-results` configuration options are supported.

```xml
  <transform-results apply="snippet" ns="http://marklogic.com/exclude-snippet" at="/ext/mlpm_modules/ml-snippeting/exclude-snippet.xqy">
    <excluded-matches>
      <json-property>ssn</json-property>
      <json-property>triple</json-property>
      <element ns="" name="ssn"/>
      <element ns="http://marklogic.com/semantics" name="triple"/>
    </excluded-matches>
    <max-matches>1</max-matches>
    <max-snippet-chars>150</max-snippet-chars>
    <per-match-tokens>20</per-match-tokens>
  </transform-results>
```
