// Fixtures for controls/rules/deserialisation.yaml
//
// STEAL: IGNORE: Deliberately vulnerable by design. The `ruleid:` cases below evaluate
// untrusted input as code. They exist to be caught, never to be copied.
//
// Run with: semgrep --test --config files/ selftest/

function unsafeEval(payload) {
  // ruleid: runwai-js-unsafe-eval-deserialisation
  return eval(payload);
}

function unsafeFunctionCtor(payload) {
  // ruleid: runwai-js-unsafe-eval-deserialisation
  return new Function(payload);
}

function safeParse(payload) {
  // ok: runwai-js-unsafe-eval-deserialisation
  return JSON.parse(payload);
}

function evalOfLiteralIsNotDeserialisation() {
  // ok: runwai-js-unsafe-eval-deserialisation
  return eval("1 + 1");
}
