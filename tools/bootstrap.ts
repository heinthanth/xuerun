#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env

import { compile } from "https://esm.sh/coffeescript";
import { join, parse, format } from "https://deno.land/std@0.139.0/path/mod.ts";

const __dirname = new URL(".", import.meta.url).pathname;
const compiler = join(__dirname, "build.coffee");
const { base: _base, ext: _ext, ...rest } = parse(compiler);
const compilerOut = format({ ...rest, name: "tmp_", ext: ".js" });

await Deno.writeTextFile(compilerOut, compile(await Deno.readTextFile(compiler)));

const cmd = ["deno", "run", "--allow-read",
  "--allow-write", "--allow-env", "--allow-run", compilerOut];
const p = Deno.run({ cmd, stderr: "inherit" });

const processStatus = await p.status();
await Deno.remove(compilerOut);
(processStatus.code != 0) && Deno.exit(processStatus.code);
