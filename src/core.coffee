import * as eta from "https://deno.land/x/eta@v1.12.3/mod.ts"

eta.configure
    tags: ["{{", "}}"]
    useWith: true
    parse: { exec: "#", raw: "%", interpolate: "" }

# magic happens here
export runRecipe = (rc, cwd, recipe, options, recon, asIngredient) ->
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

    usedCwd = currentRecipe.cwd or cwd
    dependencies.forEach (dep) ->
        # won't pass options
        if typeof dep == "string" then return runRecipe(rc, usedCwd, dep, {})

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
        runRecipe(rc, usedCwd, dep.name, depOptionToBePassed, recon, true)

    # make main recipe
    commands = currentRecipe.command
    (if typeof commands == "string" then [commands] else commands)
    .map (cmdOption) ->
        try
            if typeof cmdOption == "string" then return eta.render(cmdOption, currentOption)
            else return {...cmdOption, cmd: eta.render(cmdOption.cmd, currentOption)}
        catch err
            console.error(
                "\nxuerun: oops, something went wrong while reading command.\nError:",
                err.message, "\n")
            Deno.exit(1)
    .forEach (cmdOption) ->
        commandToRun = [
            (if typeof cmdOption == "object" and
                cmdOption.shell then cmdOption.shell else currentRecipe.shell), "-c",
            if typeof cmdOption == "string" then cmdOption else cmdOption.cmd ]

        # if recon, just show command
        if recon then return console.info(commandToRun)

        # run command
        preparedEnv = {}
        Object.entries(currentOption).forEach ([k, v]) ->
            preparedEnv[k] = switch
                when v == null then ""
                when typeof v == "undefined" then ""
                else v.toString()

        commandProcess = null
        try
            commandProcess = Deno.run
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
