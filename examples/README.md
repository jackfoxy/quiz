# Examples

Open **Examples** in the Quiz workbench, or read the
[example catalog](../desk/doc/examples.md) for source links and recorded outcomes.

- `desk/examples/props/`: passing property documents.
- `desk/examples/failing/`: intentional counterexamples and exhaustion.
- `desk/tests/examples/`: existing tutorial, boxcar and Euler test suites.

The new property documents run through the app's saved-property or draft
workflow. The three existing suites run through its saved-suite workflow or
Dojo:

```hoon
-test /=quiz=/tests/examples ~
```

All three suites pass. Legacy tutorial arms assert expected failures as
successful test assertions. New teaching failures stay outside `desk/tests/`
and do not make the default passing regression suite fail.
