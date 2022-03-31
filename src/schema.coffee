import { create, defaulted, optional, union, object, record,
    array, string, number, boolean, validate } from "https://esm.sh/superstruct";

XueRunUserCmd = union([string(), object({ shell: optional(string()), cmd: string() })]);

XueRunIngredient$option = union([string(), number(), boolean()])
export XueRunIngredient = object
    name: string(),
    options: defaulted(optional(record(string(), XueRunIngredient$option)), () => ({})),
    passParentOptions: defaulted(optional(union([boolean(), array(string())])), () => !1),

getCurrentSH = -> if Deno.build.os == "windows" then "cmd" else "sh"

XueRunRecipe$dependencies = union([string(), array(union([string(), XueRunIngredient]))])
export XueRunRecipe = object
    description: defaulted(optional(string()), () => ""),
    shell: defaulted(optional(string()), () => Deno.env.get("SHELL") || getCurrentSH()),
    command: defaulted(optional(union([string(), array(XueRunUserCmd)])), () => ""),
    passEnv: defaulted(optional(union([boolean(), array(string())])), () => !1),
    passCLI: defaulted(optional(union([boolean(), array(string())])), () => !1),
    dependencies: defaulted(optional(XueRunRecipe$dependencies), () => []),

export XueRunConfiguration = record(string(), XueRunRecipe)

createConfiguration = (userConfig) ->
    [err, data] = validate userConfig, XueRunConfiguration
    if err then throw err
    return create data, XueRunConfiguration

export default createConfiguration
