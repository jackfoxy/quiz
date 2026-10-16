# Examples

The executable example suites live in [desk/tests/examples](../desk/tests/examples):

- [Quiz tutorial](../desk/tests/examples/01-quiz-tutorial.hoon)
- [Boxcar](../desk/tests/examples/02-boxcar.hoon)
- [Euler](../desk/tests/examples/03-euler.hoon)

After copying and committing the desk to a ship, run:

```hoon
-test /=quiz=/tests/examples ~
```

All three suites pass. Properties that deliberately find counterexamples are
asserted as expected failures inside passing test arms.
