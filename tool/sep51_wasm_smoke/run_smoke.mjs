// Loads the compiled WasmGC module and runs its `main`.
//
// `dart compile wasm` emits the module beside a JavaScript init file that knows
// how to instantiate it. This script is the Node entry point that drives that
// init file, because the compiler emits a loader rather than a runnable program.
//
// An uncaught Dart error surfaces here and exits non-zero. A host stack
// overflow inside the module does not surface at all: it aborts the process,
// which is precisely the condition the harness exists to detect.

import { readFile } from 'node:fs/promises';
import { argv, exit } from 'node:process';

const [, , modulePath, loaderPath] = argv;

if (!modulePath || !loaderPath) {
  console.error('usage: node run_smoke.mjs <module.wasm> <module.mjs>');
  exit(2);
}

const loader = await import(loaderPath);
const compiled = await loader.compile(await readFile(modulePath));
const instance = await loader.instantiate(compiled, {});
await loader.invoke(instance);
