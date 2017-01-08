ci_env = System.get_env "CI"

formatters = [ExUnit.CLIFormatter] ++ if ci_env, do: [JUnitFormatter], else: []

ExUnit.start formatters: formatters
