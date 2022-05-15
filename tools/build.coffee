import { compile } from "https://esm.sh/coffeescript"
import { walkSync, ensureDirSync, emptyDir } from "https://deno.land/std@0.139.0/fs/mod.ts"
import { join, parse, format } from "https://deno.land/std@0.139.0/path/mod.ts"

__dirname = new URL(".", import.meta.url).pathname
srcPath = join(__dirname, "..", "src")
distPath = join(__dirname, "..", "tmp")
binPath = join(__dirname, "..", "bin", "xuerun")
mainMod = join(distPath, "xuerun.js")

await emptyDir(distPath)

Array(...walkSync(srcPath)).forEach (p) ->
    dist = p.path.replace(srcPath, distPath)
    if (p.isDirectory) then return ensureDirSync(p.path)
    content = Deno.readTextFileSync(p.path)
    { base: _base, ext: _ext, ...d } = parse(dist)
    compiledCode = compile(content, { bare: true }).replace(/\.coffee/g, ".js")
    Deno.writeTextFileSync(format({ ...d, ext: ".js" }), compiledCode)

for target in ["x86_64-unknown-linux-gnu", "x86_64-pc-windows-msvc", "x86_64-apple-darwin", "aarch64-apple-darwin"]
    cmd = ["deno", "compile", "--allow-read", "--allow-write", "--allow-env",
        "--allow-run", "--unstable", "--target", target, "--output", "#{binPath}-#{target}", mainMod]
    p = Deno.run({ cmd })
    processStatus = await p.status()

# bundle to JS
cmd = ["deno", "bundle", "--unstable", mainMod, "#{binPath}.js"]
p = Deno.run({ cmd })
processStatus = await p.status()

await Deno.remove(distPath, { recursive: true });
(processStatus.code != 0) and Deno.exit(processStatus.code);
