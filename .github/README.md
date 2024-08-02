# travis-shared-config
![travisci](https://img.shields.io/badge/-TravisCI-4e4847?style=flat-square&logo=travisci&logoColor=e0da53)
![yaml](https://img.shields.io/badge/-YAML-black?style=flat-square&logo=yaml&logoColor=red)
![Linux](https://img.shields.io/badge/-Linux-FCC624?style=flat-square&logo=linux&logoColor=black)

Travis v3 Shared Config is a powerful feature that allows you to create reusable configuration snippets for your Travis CI build processes. By utilizing shared configurations, you can simplify your `.travis.yml` files and ensure consistency across multiple projects.

## Overview

Travis v3 Shared Config allows users to define configuration snippets that can be shared across multiple Travis CI projects. These shared configuration snippets help reduce duplication of code and promote consistency across projects by enabling the reuse of common build configurations.

## Creating a Shared Config

To create a shared config, you need to store the configuration file in a dedicated repository. This repository should contain the set of all `yaml` files like seen in this repository.

Please refer to the [Travis CI Docs](https://docs.travis-ci.com/user/build-config-imports/) for more information on how to create a shared config.

## Importing a Shared Config

To import a shared configuration into your project's `.travis.yml` file, use the import keyword followed by the repository name and configuration file path. By default, Travis CI will look for a `.travis.yml` file in the specified repository. For instance, to import the shared config from the `my-shared-config` repository, add the following to your project's `.travis.yml` file:

```yaml
version: ~> 3.0

import:
  - source: my-username/my-shared-config:base.yml@main
    mode: merge
  - source: my-username/my-shared-config:docker-build-stage.yml@main
    if: type = pull_request
  - source: my-username/my-shared-config:cirrus/cirrus-deploy-stage.yml@main
    if: type = push

install: skip
script: skip
```

Here, `my-username` represents your GitHub username, and `my-shared-config` is the repository containing the shared configuration.

## Import Modes

Travis v3 Shared Config offers different import modes to control how the shared configuration is merged with your project's `.travis.yml` file. There are two primary import modes:

1. `deep_merge`: Merges the shared configuration recursively with your project's configuration. This mode is useful when you want to merge the shared config with your existing project config. In case of conflicts, the values in the importing file take precedence over the shared config.

2. `replace`: Replaces the importing configuration with the shared configuration. This mode is useful when you want to use the shared config as-is without merging it with your existing project config.

## Overriding Shared Configurations

You can override shared configurations by specifying the same keys in your project's .travis.yml file. The values in the importing file will take precedence over the shared config values. For example:

```yaml
version: ~> 3.0

import:
  - source: my-username/my-shared-config:docker-build-stage.yml
    mode: deep_merge

before_install:
  - echo "Project-specific before_install script"
```

In this example, the `before_install` script in the importing file will override the shared config's `before_install` script.

## Conclusion

Travis v3 Shared Config simplifies and standardizes the build process across multiple projects by allowing the reuse of common build configurations. By creating and importing shared configurations, you can reduce code duplication and ensure consistency in your CI/CD processes.

## References

- [Travis CI Docs](https://docs.travis-ci.com/user/build-config-imports/)

## License

[Apache 2.0](LICENSE)
