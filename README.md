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

Note: `perferred-elements` will effectively be ignored.
