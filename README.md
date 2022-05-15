# XueRun ( 雪 run )

Just a make-like task runner but with more power! It's written in CoffeeScript + Deno.

## Downloads

Go to Release page and download builds!
And move it to ur path. Eg. `/usr/bin`, `/usr/local/bin`, etc. For windows, the same :P.

## Configurations

Complete Configurations Example:

```yaml
dependOnMeToo:
  description: another task
  # cwd: /some/path/too
  command:
  - cmd: echo "I can read {{ opt.release }} if 'dependOnMe' task call me"
    when: opt.release # if opt.release is true
  - cmd: echo "Since passParentOptions is true in 'dependOnMe' task"
    when: opt.release # if opt.release is true
  passEnv: [ PATH ] # u need to pass env to use ur PATH.
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

## How to Build

First, clone this repo. Then, run "tools/bootstrap.ts"

```shell
deno run tools/bootstrap.ts
```

## License

XueRun is licensed under BSD-2-Clause. For more, see [LICENSE](LICENSE).
