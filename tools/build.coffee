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

cmd = ["deno", "compile", "--allow-read", "--allow-write",
    "--allow-env", "--allow-run", "--unstable", "--output", binPath, mainMod]
p = Deno.run({ cmd })

processStatus = await p.status()
# await Deno.remove(distPath, { recursive: true });
(processStatus.code != 0) and Deno.exit(processStatus.code);
