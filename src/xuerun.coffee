import { parse } from "https://deno.land/std@0.132.0/flags/mod.ts";
import { parse as parseYAML } from "https://deno.land/std@0.132.0/encoding/yaml.ts"
import { YAMLError } from "https://deno.land/std@0.132.0/encoding/_yaml/error.ts"
import { printf } from "https://deno.land/std@0.132.0/fmt/printf.ts"
import { StructError } from "https://esm.sh/superstruct"
import { runRecipe } from "./core.coffee"
import createConfiguration from "./schema.coffee"

loadXueRunTasks = (path) ->
    try
        content = Deno.readTextFileSync(path)
        return createConfiguration(parseYAML(content))
    catch error
        if error instanceof YAMLError or error instanceof StructError
            console.error(
                "\nxuerun: oops, invalid .xuerun tasks.\nError:", error.message, "\n")
        else console.error(
                "\nxuerun: oops, can't read .xuerun tasks.\nError:", error.message, "\n")
        Deno.exit(1)

printVersion = () ->
    console.log() # print padding
    ascii = [
        'y88b    /                    888~-_                    '
        ' y88b  /  888  888  e88~~8e  888   \\  888  888 888-~88e'
        '  y88b/   888  888 d888  88b 888    | 888  888 888  888'
        '  /y88b   888  888 8888__888 888   /  888  888 888  888'
        ' /  y88b  888  888 y888    , 888_-~   888  888 888  888'
        '/    y88b "88_-888  "88___/  888 ~-_  "88_-888 888  888'].join("\n")
    console.info("%s\n", ascii)
    printf("XueRun v%s ( %s / %s )\n", "0.1.0", Deno.build.os, Deno.build.arch)
    currentYear = new Date().getFullYear()
    printf("(c) 2022%s Hein Thant Maung Maung. Licensed under BSD-2-CLAUSE.\n\n",
        if currentYear == 2022 then "" else " - #{currentYear}")

printHelp = (shouldPrintVersion = true) ->
    if shouldPrintVersion then printVersion()
    helpStrings = [
        "General:",
        "    xuerun [tasks]... [options]...",
        "",
        "Options:",
        "    -t, --tasks        path to xuerun tasks ( default: tasks.xuerun ).",
        "    -n, --recon        do nothing, print commands."
        "",
        "    -v, --version      print xuerun version and others.",
        "    -h, --help         print this help message.",
        "",
        "For docs, usage, etc., visit https://github.com/heinthanth/xuerun."].join("\n")
    console.info(helpStrings, "\n")

actionKind =
    RUN_RECIPE: "RUN_RECIPE"
    PRINT_HELP: "PRINT_HELP"
    PRINT_VERSION: "PRINT_VERSION"

parseCmdOption = () ->
    {'_': positional, '--': cliRest, ...options} = parse Deno.args, { "--": true }
    userOption =
        action: actionKind.RUN_RECIPE,
        recon: !1,
        recipes: []
        options: {}
        tasksPath: "tasks.xuerun"

    # parse options
    Object.entries(options).forEach ([k, v]) -> switch k
        when "h", "help" then userOption.action = actionKind.PRINT_HELP
        when "v", "version" then userOption.action = actionKind.PRINT_VERSION
        when "t", "tasks" then userOption.tasksPath =
            if typeof v == "string" or typeof v == "number" then v.toString() else "tasks.xuerun"
        when "n", "recon" then userOption.recon = true

    # remove default CLI arguments
    {h, v, t, n, help, version, tasks, recon, ...restCLIargs} = options
    # parse options passed with -- --something
    {'_': _restPositional, ...optionsFromCLIrestOptions} = parse(cliRest)
    # combine options
    userOption.options = { ...restCLIargs, ...optionsFromCLIrestOptions }
    return { ...userOption, recipes: positional }

programMain = () ->
    {recipes, tasksPath, action, options, recon} = parseCmdOption()
    if action == actionKind.PRINT_HELP then return printHelp()
    if action == actionKind.PRINT_VERSION then return printVersion()

    # load and run
    xueRunRc = loadXueRunTasks(tasksPath)
    if recipes.length == 0
        if xueRunRc.hasOwnProperty("all")
            return runRecipe(xueRunRc, null, recipes, userOption)
        else console.error("\nxuerun: oops, no recipe given, nothing to do!\n"); Deno.exit(1)
    recipes.forEach (recipe) -> await runRecipe(xueRunRc, null, recipe, options, recon, !1)

# call main function
if import.meta.main then programMain()
