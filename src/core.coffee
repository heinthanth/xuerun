import * as eta from "https://deno.land/x/eta@v1.12.3/mod.ts"
import { resolve } from "https://deno.land/std@0.139.0/path/mod.ts";

eta.configure
    tags: ["{{", "}}"]
    varName: "opt"
    parse: { exec: "#", raw: "%", interpolate: "" }

# magic happens here
export runRecipe = (rc, recipe, options, recon, asIngredient) ->
    previousCwd = Deno.cwd()
    if not (rc.hasOwnProperty(recipe))
        console.error("\nxuerun: oops, recipe '#{recipe}' is not in .xuerun tasks!\n")
        Deno.exit(1)
    # resolve dependencies
    currentRecipe = rc[recipe]

    currentOption = {}
    if typeof currentRecipe.passEnv == "boolean" and currentRecipe.passEnv
        currentOption = { ...currentOption, ...Deno.env.toObject() }
    else if Array.isArray(currentRecipe.passEnv)
        currentOption = { ...currentOption }
        currentRecipe.passEnv.forEach (env) -> currentOption[env] = Deno.env.get(env)
    else ### do pass env ###

    if asIngredient then currentOption = { ...currentOption, ...options }
    else if typeof currentRecipe.passCLI == "boolean" and currentRecipe.passCLI
        currentOption = { ...currentOption, ...options }
    else if Array.isArray(currentRecipe.passCLI)
        # since current task is main task ( not ingredient ), options point to CLI option
        currentOption = { ...currentOption }
        currentRecipe.passCLI.forEach (opt) -> currentOption[opt] = options[opt] || ""
    else ### don't pass options ###

    dependencies = if typeof currentRecipe.dependencies ==
        "string" then currentRecipe.dependencies.split(" ") else currentRecipe.dependencies

    usedCwd = currentRecipe.cwd and resolve(Deno.cwd(), currentRecipe.cwd) or Deno.cwd()

    for dep in dependencies
        # won't pass options
        if typeof dep == "string" then await runRecipe(rc, dep, {}, recon, true); continue

        depOption = { ...dep.options }
        if typeof dep.passParentOptions == "boolean" and dep.passParentOptions
            depOption = { ...currentOption, ...depOption }
        else if Array.isArray(dep.passParentOptions)
            dep.passParentOptions.forEach (opt) -> depOption[opt] = currentOption[opt]
        else ### do pass parent option ###

        # resolve ( compile ) option value with current option
        depOptionToBePassed = {}
        Object.entries(depOption).forEach ([option, value]) ->
            unless typeof value == "string" then return depOptionToBePassed[option] = value
            try depOptionToBePassed[option] = eta.render(value, currentOption)
            catch err
                console.error("\nxuerun: oops, something went wrong while reading options.\nError:",
                    err.message, "\n")
                Deno.exit(1)
        await runRecipe(rc, dep.name, depOptionToBePassed, recon, true)

    # change to given cwd for Deno process
    Deno.chdir(usedCwd)
    # make main recipe
    _commands = currentRecipe.command

    for _cmdOption in (if typeof _commands == "string" then [_commands] else _commands)
        try
            if typeof _cmdOption == "string"
                cmdOption = eta.render(_cmdOption, currentOption)
            else cmdOption = {..._cmdOption, cmd: eta.render(_cmdOption.cmd, currentOption)}
        catch err
            console.error(
                "\nxuerun: oops, something went wrong while reading command.\nError:",
                err.message, "\n")
            Deno.exit(1)

        # used by eval
        globalThis.opt = currentOption
        # don't run if eval when is false
        if typeof cmdOption == "object" and not Boolean(eval(cmdOption.when))
            continue
        # I don't need here
        delete globalThis.opt

        commandToRun = [
            (if typeof cmdOption == "object" and
                cmdOption.shell then cmdOption.shell else currentRecipe.shell), "-c",
            if typeof cmdOption == "string" then cmdOption else cmdOption.cmd ]

        # if recon, just show command
        if recon then console.info(commandToRun); continue

        # run command
        preparedEnv = {}
        Object.entries(currentOption).forEach ([k, v]) ->
            preparedEnv[k] = switch
                when v == null then ""
                when typeof v == "undefined" then ""
                else v.toString()

        commandProcess = null
        try
            commandProcess = await Deno.run
                cmd: commandToRun
                stdin: "inherit"
                stdout: "inherit"
                stderr: "inherit"
                clearEnv: true
                env: preparedEnv
                cwd: usedCwd
        catch err
            console.error("\nxuerun: Something went wrong while running command", commandToRun)
            console.error("Error:", err.message, "\n")

        if commandProcess == null then Deno.exit(1)
        status = await commandProcess.status()
        if status.code != 0
            console.error("\nxuerun: command exit with exit code:", status.code, "\n")
            Deno.exit(status.code)
    # back to previous cwd ( root of project )
    Deno.chdir(previousCwd)