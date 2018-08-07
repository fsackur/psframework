# PSFramework

A library that solves commonly-encountered requirements.

# The problem

There are a number of requirements that most software teams encounter and must solve themselves - for example, logging.

When every team solves these problems independently, they must:

- spend development time creating boilerplate code
- spend maintenance time supporting this code

# The solution

PSFramework is an _actively-maintained_ library of solutions to these common problems, engineered to be _simple-to-use_ but with great flexibility when needed.

PSFramework is engineered for performance.

PSFramework is engineered for reliability, and is thoroughly unit-tested and soak-tested.

Functionality covers four main areas:

- Logging, and handling verbose and debug messages
- Storing and retrieving per-module configuration
- Background tasks
- Module development and increasing usability of developed modules

These areas are a subset of what PSFramework offers. PSFramework ha a broad scope. But if even one of these is a function that your team has to perform, then PSFramework can potentially save you a large number of hours of effort, while also increasing the quality of your applications.

**Get back to what you do best: delivering business value!**

## Logging

- Replace all `Write-Log`, `Write-Verbose`, `Write-Debug` and `Write-Host` messages with `Write-PSFMessage`.

All messages are logged by default. Logging is asynchronous, improving performance. Logging handles all potential issues such as dealing with a filesystem.

You can easily set message display dynamically, so that end-users have a curated error experience but developers get enhanced exception functionality.

## Per-module configuration

- Replace all module registry storage or JSON / XML /YAML storage with `Get-` and `Set-PSFConfig`.

Configuration is handled per-module. You do not need to think about where to store configuration or how to validate it. You can optionally set validation per configuration item. _It just works._

## Background tasks

- Replace all Runspace, Job and Event code with `Register-PSFTaskEngineTask`.

PSFramework tasks are managed by the PSFramework task engine. This performs scheduling and clean-up. Tasks can be run once, or on a schedule. The task engine handles getting results back to you.

Tasks scheduled with PSFramework are easy to debug with `Write-PSFMessage`.

## Development and usability

- Replace all parameter validation and tab completion code with `Register-PSFTeppArgumentCompleter` and the custom parameter attributes.

(WIP)