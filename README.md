# XueRun ( 雪 run )

Just a make-like task runner but with more power! It's written in CoffeeScript + Deno.

## Downloads

Go to Release page and download builds!
And move it to ur path. Eg. `/usr/bin`, `/usr/local/bin`, etc. For windows, the same :P.

## Configurations

General usage is:

```text
xuerun [tasks]... [options]...
```

TL;DR

```shell
$ xuerun                      # will execute 'all' task if exist
$ xuerun task-name-to-execute # will execute 'task-name-to-execute'
$ xuerun -t some-tasks-path   # will look for task in 'some-tasks-path'
$ xuerun -n some-task         # will print commands to run ( won't execute )
```

### Tasks Path ( `--tasks, -t` option )

Unless `--tasks ( -t )` is given, XueRun will look for `tasks.xuerun`. If `tasks.xuerun` exists, XueRun will use that.

```shell
$ xuerun someName # xuerun will look for someName in tasks.xuerun
$ xuerun -t example.xuerun someName # xuerun will look for someName in example.xuerun
```

### Task Name ( `[tasks]` )

Unless task names are given, XueRun will look for a task named `all`. If `all` task exists, XueRun will execute that.

```shell
$ xuerun task-name-to-execute
```

You can give multiple task name too.

```shell
$ xuerun taskOne taskTwo taskThree # these tasks will run in sequantial order.
```

### Recon ( `--recon, -n` option )

Use `--recon ( -n )` to emulate task execution ( but won't work in some edge cases ).

```shell
$ xuerun -n some-task # xuerun will print commands instead of executing
```

### Complete Configurations Example

```yaml
dependOnMeToo:
  description: another task
  # cwd: /some/path/too
  command:
  - cmd: echo "I can read {{ opt.release }} if 'dependOnMe' task call me"
    when: opt.release # if opt.release is true
  - cmd: echo "Since passParentOptions is true in 'dependOnMe' task"
    when: opt.release # if opt.release is true
  passEnv: [ PATH ] # u need to pass env to use ur PATH. Pass true to pass all environment variables
dependOnMe:
  description: some task
  # cwd: / # try change cwd and see {{ Deno.cwd() }} output!
  shell: bash # default shell
  dependencies:
  - name: dependOnMeToo
    passParentOptions: true
  command:
  - cmd: echo "I can read {{ opt.FOO }}"
    shell: zsh # u can use another shell rather than default one
  - cmd: echo "Don't run me unless status is 'true'"
    when: opt.status == 'true'
  - echo "I'm a command too. In {{ Deno.cwd() }}" # deno expressions are supported
taskName:
  description: a description
  dependencies:
  - name: dependOnMe
    options:
      FOO: bar
      status: "{{ opt.status == 1 }}"
      release: "{{ opt.release }}" # u can use --release CLI option if passCLI is true
  passCLI: true
  command: echo "this is main task"
```

I think this example show u a lot! Have Fun xuerunning!

## Some Notes

Here's some notes to be considered.

### Option passing

If u specified `passEnv` and `passCLI`, given env and CLI arguments will be passed to `opt` object and can be used with `{{}}`



### When Option ( WARNING )

This `taskName > command > subcommand > when` ( when ) expression is evaluated using `eval` function from javascript and can inject raw JS codes. So, use at ur own risk.

```yaml
- cmd: echo "Don't run me unless status is 'true'"
  when: opt.status == 'true'
```

### JS Expression

You can use `{{ expression }}` in commands, options, etc. XueRun use `eta` to render those. string templates. Keep in mind, raw JS code can be injected too. So, use at ur own risk.

```yaml
command:
- cmd: echo "it's PATH env => {{ opt.PATH }}  and CLI release option => {{ opt.release }}"
passEnv: [ PATH ]
passCLI: true
```

Then, when u run with `xuerun taskName --release`, `opt.PATH` will be replaced with ur PATH env and `opt.release` will be replaced with `true`.

## How to Build

First, clone this repo. Then, run "tools/bootstrap.ts"

```shell
deno run tools/bootstrap.ts
```

## License

XueRun is licensed under BSD-2-Clause. For more, see [LICENSE](LICENSE).
 